export function connectToDevelopmentServer(port, init) {
  const server = new WebSocket(`ws://localhost:${port}`);
  server.onerror = () => server.close();
  server.onclose = () => setTimeout(connectToDevelopmentServer, 2000);
  server.onmessage = ({ data }) => {
    Elm = null;
    eval(data);
    init();
  };
}
