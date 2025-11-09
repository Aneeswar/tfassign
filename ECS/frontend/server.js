const express = require('express');
const path = require('path');

// NOTE: Proxy middleware is REMOVED, as the ALB handles routing /api/*

// FIX: Remove the BACKEND_URL check and proxy setup
/*
const BACKEND_URL = process.env.BACKEND_URL;
if (!BACKEND_URL) {
    console.error('Error: BACKEND_URL is missing!');
    process.exit(1);
}
*/

const app = express();
const PORT = 3000;

// FIX: Remove Proxy Setup
/*
app.use('/api', createProxyMiddleware({
    target: BACKEND_URL, 
    changeOrigin: true,
    pathRewrite: {
        '^/api': '', 
    },
}));
*/

// 1. Serve static files (HTML, CSS, client-side JS)
app.use(express.static(path.join(__dirname, 'public')));

// 2. A default route to serve the main HTML page (Acts as Health Check)
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// START SERVER
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Frontend server is running on http://localhost:${PORT}`);
    // FIX: Remove proxy log
    console.log(`Frontend serving static files and relying on ALB for /api routing.`); 
});