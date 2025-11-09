const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

// Read the single URL environment variable
const BACKEND_URL = process.env.BACKEND_URL;

if (!BACKEND_URL) {
    console.error('Error: BACKEND_URL is missing!');
    process.exit(1);
}

const app = express();
const PORT = 3000;

// Setup the Proxy using the simple URL string
app.use('/api', createProxyMiddleware({
    target: BACKEND_URL, // <--- Pass the full string
    changeOrigin: true,
    pathRewrite: {
        '^/api': '', 
    },
}));

// 2. Serve static files (HTML, CSS, client-side JS)
app.use(express.static(path.join(__dirname, 'public')));

// 3. A default route to serve the main HTML page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Frontend server is running on http://localhost:${PORT}`);
    console.log(`Proxying /api requests to ${BACKEND_URL}`); 
});
