import { useState, useEffect } from 'react';
import { Event, supabase } from '../lib/supabase';
import { Calendar, MapPin, Users, CheckCircle, Loader2 } from 'lucide-react';

interface EventsListProps {
  events: Event[];
  userId?: string;
  onRegister: () => void;
}

export function EventsList({ events, userId, onRegister }: EventsListProps) {
  const [registeredEvents, setRegisteredEvents] = useState<Set<string>>(new Set());
  const [registering, setRegistering] = useState<string | null>(null);

  useEffect(() => {
    loadRegistrations();
  }, [userId]);

  const loadRegistrations = async () => {
    if (!userId) return;

    const { data } = await supabase
      .from('event_registrations')
      .select('event_id')
      .eq('user_id', userId)
      .eq('status', 'registered');

    if (data) {
      setRegisteredEvents(new Set(data.map((reg) => reg.event_id)));
    }
  };

  const handleRegister = async (eventId: string) => {
    if (!userId) return;

    setRegistering(eventId);

    const { error } = await supabase
      .from('event_registrations')
      .insert({
        user_id: userId,
        event_id: eventId,
        status: 'registered',
      });

    if (!error) {
      setRegisteredEvents(new Set([...registeredEvents, eventId]));
      onRegister();
    }

    setRegistering(null);
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (events.length === 0) {
    return (
      <div className="text-center py-12">
        <Calendar className="w-16 h-16 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">No upcoming events</h3>
        <p className="text-gray-600">Check back later for new events and workshops.</p>
      </div>
    );
  }

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Upcoming Events</h2>

      <div className="grid gap-6">
        {events.map((event) => {
          const isRegistered = registeredEvents.has(event.id);
          const isRegistering = registering === event.id;

          return (
            <div
              key={event.id}
              className="border border-gray-200 rounded-xl p-6 hover:shadow-md transition"
            >
              <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">
                    {event.title}
                  </h3>
                  {event.description && (
                    <p className="text-gray-600 mb-4">{event.description}</p>
                  )}

                  <div className="space-y-2">
                    <div className="flex items-center gap-2 text-gray-700">
                      <Calendar className="w-5 h-5 text-blue-600" />
                      <span>{formatDate(event.event_date)}</span>
                    </div>

                    {event.location && (
                      <div className="flex items-center gap-2 text-gray-700">
                        <MapPin className="w-5 h-5 text-blue-600" />
                        <span>{event.location}</span>
                      </div>
                    )}

                    {event.max_participants > 0 && (
                      <div className="flex items-center gap-2 text-gray-700">
                        <Users className="w-5 h-5 text-blue-600" />
                        <span>Max {event.max_participants} participants</span>
                      </div>
                    )}
                  </div>
                </div>

                <div className="flex-shrink-0">
                  {isRegistered ? (
                    <div className="flex items-center gap-2 px-6 py-3 bg-green-50 text-green-700 rounded-lg border border-green-200">
                      <CheckCircle className="w-5 h-5" />
                      Registered
                    </div>
                  ) : (
                    <button
                      onClick={() => handleRegister(event.id)}
                      disabled={isRegistering}
                      className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 flex items-center gap-2"
                    >
                      {isRegistering ? (
                        <>
                          <Loader2 className="w-5 h-5 animate-spin" />
                          Registering...
                        </>
                      ) : (
                        'Register Now'
                      )}
                    </button>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
