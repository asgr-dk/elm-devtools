function connectDevTools(init, port = 1337) {
  const server = new WebSocket(`ws://localhost:${port}`);
  server.onerror = () => server.close();
  server.onclose = () => setTimeout(connectDevTools, 2000);
  server.onmessage = ({ data }) => {
    Elm = null;
    eval(data);
    init();
  };
}
