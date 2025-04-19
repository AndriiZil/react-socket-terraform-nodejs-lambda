'use client';

import { useState } from 'react';
import { useWebSocket } from '@/hooks/useWebSocket';

export default function Home() {
  const [message, setMessage] = useState('');
  const { isConnected, messages, sendMessage } = useWebSocket(process.env.NEXT_PUBLIC_WEBSOCKET_URL || '');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (message.trim()) {
      sendMessage({
        action: 'sendMessage',
        data: { message }
      });
      setMessage('');
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="z-10 max-w-5xl w-full">
        <h1 className="text-4xl font-bold mb-8">WebSocket Chat</h1>
        
        <div className="bg-white rounded-lg shadow p-6">
          <div className="mb-4">
            Connection status: {isConnected ? 
              <span className="text-green-500">Connected</span> : 
              <span className="text-red-500">Disconnected</span>
            }
          </div>

          <div className="h-96 overflow-y-auto mb-4 p-4 border rounded">
            {messages.map((msg, index) => (
              <div key={index} className="mb-2">
                <strong>{msg.data.message}</strong>
              </div>
            ))}
          </div>

          <form onSubmit={handleSubmit} className="flex gap-2">
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="flex-1 px-4 py-2 border rounded"
              placeholder="Type a message..."
            />
            <button 
              type="submit"
              className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
              disabled={!isConnected}
            >
              Send
            </button>
          </form>
        </div>
      </div>
    </main>
  );
} 