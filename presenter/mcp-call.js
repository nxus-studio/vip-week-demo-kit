// Minimal MCP stdio client used by the presenter's cleanup: node mcp-call.js <tool> '<json args>' (run inside the demo clone)
const { spawn } = require('child_process');
const [tool, rawArgs] = process.argv.slice(2);
const srv = spawn('lemma', ['mcp'], { env: { ...process.env, LEMMA_MCP_NO_PROXY: '1' }, stdio: ['pipe', 'pipe', 'ignore'] });
let buf = '';
const send = (m) => srv.stdin.write(JSON.stringify(m) + '\n');
const timer = setTimeout(() => { console.error('timeout'); srv.kill(); process.exit(2); }, 90000);
srv.stdout.on('data', (d) => {
  buf += d;
  let i;
  while ((i = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, i); buf = buf.slice(i + 1);
    let msg; try { msg = JSON.parse(line); } catch { continue; }
    if (msg.id === 1) {
      send({ jsonrpc: '2.0', method: 'notifications/initialized' });
      send({ jsonrpc: '2.0', id: 2, method: 'tools/call', params: { name: tool, arguments: JSON.parse(rawArgs || '{}') } });
    } else if (msg.id === 2) {
      clearTimeout(timer);
      if (msg.error) console.log('ERROR', JSON.stringify(msg.error));
      else for (const c of msg.result.content || []) console.log(c.text);
      srv.kill(); process.exit(0);
    }
  }
});
send({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'vip-week-demo-kit', version: '0' } } });
