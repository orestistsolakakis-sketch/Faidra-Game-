using System;
using System.Collections.Generic;
using System.Linq;
using Lumenfall.Narrative.Relationships;

namespace Lumenfall.Narrative.Events;

/// <summary>
/// The living-world engine. Holds every registered <see cref="WorldEvent"/> and
/// re-evaluates them whenever World Time or a world fact changes: dormant events
/// whose condition becomes true ACTIVATE; active events past their deadline
/// EXPIRE (applying their default outcome). The player resolves an active event
/// by choosing one of its outcomes. (See docs/EVENT_SYSTEM_BIBLE.md.)
///
/// Pure C# with no Godot dependency — unit-testable and serializable. The
/// <see cref="World"/> autoload owns an instance, feeds it clock/state changes,
/// and re-broadcasts its activity as Godot signals.
///
/// Because event effects can change world state (and register further events),
/// one <see cref="Evaluate"/> can cascade — so it loops until the world settles,
/// which is how a single choice ripples down a consequence chain in one tick.
/// </summary>
public sealed class EventManager
{
    private const int MaxCascadePasses = 64; // safety net against pathological content loops

    private readonly Dictionary<string, WorldEvent> _events = new();

    // Live runtime state, kept separate from the immutable definitions so saves
    // only need to persist this, and definitions can be re-registered on load.
    private readonly Dictionary<string, EventStatus> _status = new();
    private readonly Dictionary<string, long> _activatedAt = new();

    private readonly ConsequenceContext _context;
    private bool _evaluating;

    /// <summary>Raised when an event becomes live.</summary>
    public event Action<WorldEvent>? EventActivated;

    /// <summary>Raised when the player resolves an event. Args: the event and the chosen outcome id.</summary>
    public event Action<WorldEvent, string>? EventResolved;

    /// <summary>Raised when an event's deadline passes unresolved.</summary>
    public event Action<WorldEvent>? EventExpired;

    public EventManager(WorldClock clock, WorldState state, RelationshipModel relationships)
    {
        _context = new ConsequenceContext(clock, state, this, relationships);
    }

    /// <summary>Register an event definition. Starts Dormant unless already tracked.</summary>
    public void Register(WorldEvent evt)
    {
        _events[evt.Id] = evt;
        if (!_status.ContainsKey(evt.Id))
            _status[evt.Id] = EventStatus.Dormant;
    }

    /// <summary>Current lifecycle status of an event (Dormant if unknown).</summary>
    public EventStatus StatusOf(string id) =>
        _status.TryGetValue(id, out EventStatus s) ? s : EventStatus.Dormant;

    /// <summary>All events currently live and awaiting resolution, highest priority first.</summary>
    public IEnumerable<WorldEvent> ActiveEvents =>
        _events.Values
            .Where(e => StatusOf(e.Id) == EventStatus.Active)
            .OrderByDescending(e => e.Priority);

    /// <summary>
    /// Re-evaluate all events against the current world. Activates newly-triggered
    /// events and expires overdue ones, looping until no further change so a
    /// cascade of effects resolves fully. Safe to call often; it is cheap when
    /// nothing changes and re-entrancy-guarded.
    /// </summary>
    public void Evaluate()
    {
        if (_evaluating)
            return; // an effect triggered another Evaluate; the outer loop will catch it
        _evaluating = true;
        try
        {
            for (int pass = 0; pass < MaxCascadePasses; pass++)
            {
                bool changed = false;

                // Expire overdue actives first (a closing window shouldn't be
                // pre-empted by something it, in turn, unlocks this same tick).
                foreach (WorldEvent evt in _events.Values.ToList())
                {
                    if (StatusOf(evt.Id) != EventStatus.Active || evt.DeadlineMinutes is not long deadline)
                        continue;
                    if (_context.Clock.TotalMinutes >= _activatedAt[evt.Id] + deadline)
                    {
                        Expire(evt);
                        changed = true;
                    }
                }

                // Activate anything whose condition is now met.
                foreach (WorldEvent evt in _events.Values.ToList())
                {
                    if (StatusOf(evt.Id) != EventStatus.Dormant)
                        continue;
                    if (evt.Condition(_context))
                    {
                        Activate(evt);
                        changed = true;
                    }
                }

                if (!changed)
                    return;
            }
            throw new InvalidOperationException(
                "Event evaluation did not settle — likely a content loop where effects keep " +
                "re-triggering conditions. Check recently added events.");
        }
        finally
        {
            _evaluating = false;
        }
    }

    /// <summary>
    /// The player chooses <paramref name="outcomeId"/> on a live event. Applies
    /// the outcome's effect and marks the event Resolved. No-op if the event is
    /// not currently active or the outcome does not exist.
    /// </summary>
    public bool Resolve(string eventId, string outcomeId)
    {
        if (!_events.TryGetValue(eventId, out WorldEvent? evt) || StatusOf(eventId) != EventStatus.Active)
            return false;
        if (!evt.Outcomes.TryGetValue(outcomeId, out EventOutcome? outcome))
            return false;

        _status[eventId] = EventStatus.Resolved;
        outcome.Apply(_context);
        EventResolved?.Invoke(evt, outcomeId);

        Evaluate(); // the resolution may have unlocked or expired other events
        return true;
    }

    private void Activate(WorldEvent evt)
    {
        _status[evt.Id] = EventStatus.Active;
        _activatedAt[evt.Id] = _context.Clock.TotalMinutes;
        evt.OnActivate?.Invoke(_context);
        EventActivated?.Invoke(evt);
    }

    private void Expire(WorldEvent evt)
    {
        _status[evt.Id] = EventStatus.Expired;
        evt.OnExpire?.Invoke(_context);
        EventExpired?.Invoke(evt);
    }

    // --- Serialization -------------------------------------------------------

    /// <summary>Capture runtime event state for a save (definitions are not saved).</summary>
    public EventManagerData Snapshot() =>
        new(new Dictionary<string, EventStatus>(_status), new Dictionary<string, long>(_activatedAt));

    /// <summary>Restore runtime event state from a save. Fires no events.</summary>
    public void Restore(EventManagerData data)
    {
        _status.Clear();
        foreach ((string id, EventStatus s) in data.Status)
            _status[id] = s;

        _activatedAt.Clear();
        foreach ((string id, long minutes) in data.ActivatedAt)
            _activatedAt[id] = minutes;
    }

    /// <summary>Clear all runtime state (definitions stay registered) for a new game.</summary>
    public void Reset()
    {
        _status.Clear();
        _activatedAt.Clear();
        foreach (string id in _events.Keys)
            _status[id] = EventStatus.Dormant;
    }
}

/// <summary>Serializable snapshot of an <see cref="EventManager"/>'s runtime state.</summary>
public sealed record EventManagerData(
    IReadOnlyDictionary<string, EventStatus> Status,
    IReadOnlyDictionary<string, long> ActivatedAt);
