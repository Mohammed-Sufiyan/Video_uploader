const express = require('express');
const AWS = require('aws-sdk');
const cors = require('cors');
const app = express();
const port = 3000;

// Configure AWS SDK
AWS.config.update({
  accessKeyId: 'YOUR_ACCESS_KEY_ID',
  secretAccessKey: 'YOUR_SECRET_ACCESS_KEY',
  region: 'us-east-1', // or your region
  endpoint: 'https://moore-market.objectstore.e2enetworks.net',
  s3ForcePathStyle: true, // Required for S3-compatible services
});

const s3 = new AWS.S3();

// Middleware
app.use(cors());
app.use(express.json());

// Generate presigned URL for upload
app.post('/api/presigned-url', async (req, res) => {
  try {
    const { fileName, destinationPath, contentType, bucket } = req.body;

    if (!fileName || !destinationPath || !contentType || !bucket) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    // Generate presigned URL
    const params = {
      Bucket: bucket,
      Key: destinationPath,
      ContentType: contentType,
      Expires: 3600, // 1 hour
    };

    const presignedUrl = s3.getSignedUrl('putObject', params);

    res.json({
      presignedUrl: presignedUrl,
      bucket: bucket,
      key: destinationPath,
      expiresIn: 3600,
    });

  } catch (error) {
    console.error('Error generating presigned URL:', error);
    res.status(500).json({ error: 'Failed to generate presigned URL' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Backend server running on port ${port}`);
  console.log(`Health check: http://localhost:${port}/health`);
  console.log(`Presigned URL endpoint: http://localhost:${port}/api/presigned-url`);
});

module.exports = app;
