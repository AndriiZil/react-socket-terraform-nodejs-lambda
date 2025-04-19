import { useEffect, useRef, useState, useCallback } from 'react';

interface WebSocketMessage {
  action: string;
  data: any;
}

export const useWebSocket = (url: string) => {
  const ws = useRef<WebSocket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [messages, setMessages] = useState<WebSocketMessage[]>([]);

  const connect = useCallback(() => {
    ws.current = new WebSocket(url);

    ws.current.onopen = () => {
      console.log('Connected to WebSocket');
      setIsConnected(true);
    };

    ws.current.onclose = () => {
      console.log('Disconnected from WebSocket');
      setIsConnected(false);
      // Attempt to reconnect after 2 seconds
      setTimeout(connect, 2000);
    };

    ws.current.onmessage = (event: MessageEvent) => {
      const message = JSON.parse(event.data);
      setMessages((prev: WebSocketMessage[]) => [...prev, message]);
    };

    ws.current.onerror = (error: Event) => {
      console.error('WebSocket error:', error);
    };
  }, [url]);

  const sendMessage = useCallback((message: WebSocketMessage) => {
    if (ws.current?.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(message));
    } else {
      console.error('WebSocket is not connected');
    }
  }, []);

  useEffect(() => {
    connect();
    return () => {
      ws.current?.close();
    };
  }, [connect]);

  return {
    isConnected,
    messages,
    sendMessage,
  };
}; 