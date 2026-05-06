export const env = {
  port: process.env.PORT || 4000,
  clientUrl: process.env.CLIENT_URL || 'http://localhost:5173',
  take60StorageBucket:
    process.env.TAKE60_STORAGE_BUCKET ||
    process.env.FIREBASE_STORAGE_BUCKET ||
    '',
  take60CdnBaseUrl: process.env.TAKE60_CDN_BASE_URL || '',
  take60TranscoderToken: process.env.TAKE60_TRANSCODER_TOKEN || '',
};
