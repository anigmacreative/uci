// Universal Creative Identity Types
export interface UniversalCreativeID {
  id: string; // Unique identifier derived from biometric + blockchain
  version: number;
  createdAt: Date;
  updatedAt: Date;
  status: 'pending' | 'verified' | 'suspended' | 'revoked';
  
  // Core identity data
  biometricHash: string; // Hashed biometric identifier
  walletAddress: string; // Blockchain wallet address
  publicKey: string; // Public key for verification
  
  // Verification levels
  verificationLevel: number; // 0-100 trust score
  verificationMethods: VerificationMethod[];
  
  // Platform connections
  connectedPlatforms: Map<string, PlatformConnection>;
  
  // Content authenticity
  contentCredentials: ContentCredential[];
  authenticityScore: number;
}

export interface VerificationMethod {
  type: 'biometric' | 'government_id' | 'social_proof' | 'platform_verification' | 'community_vouching';
  status: 'verified' | 'pending' | 'failed' | 'expired';
  verifiedAt: Date;
  expiresAt?: Date;
  confidence: number; // 0-1
  metadata: Record<string, any>;
}

export interface PlatformConnection {
  platformId: string; // 'tiktok', 'instagram', 'youtube', etc.
  username: string;
  userId: string;
  displayName: string;
  profileUrl: string;
  
  // Connection status
  connectionStatus: 'connected' | 'verified' | 'expired' | 'revoked';
  connectedAt: Date;
  lastSyncAt: Date;
  
  // Authentication
  accessToken: string; // Encrypted
  refreshToken?: string; // Encrypted  
  tokenExpiresAt: Date;
  
  // Platform-specific data
  platformData: PlatformSpecificData;
  metrics: PlatformMetrics;
  
  // Sync settings
  syncSettings: PlatformSyncSettings;
}

export interface PlatformSpecificData {
  // TikTok specific
  tiktok?: {
    followerCount: number;
    followingCount: number;
    likesCount: number;
    videoCount: number;
    verified: boolean;
    bio: string;
    avatarUrl: string;
  };
  
  // Instagram specific
  instagram?: {
    followerCount: number;
    followingCount: number;
    mediaCount: number;
    verified: boolean;
    bio: string;
    avatarUrl: string;
    businessAccount: boolean;
  };
  
  // YouTube specific
  youtube?: {
    subscriberCount: number;
    videoCount: number;
    viewCount: number;
    channelId: string;
    description: string;
    thumbnailUrl: string;
    verified: boolean;
  };
  
  // LinkedIn specific
  linkedin?: {
    connectionCount: number;
    headline: string;
    summary: string;
    industry: string;
    location: string;
    profilePictureUrl: string;
  };
}

export interface PlatformMetrics {
  totalReach: number;
  engagementRate: number;
  averageViews: number;
  averageLikes: number;
  averageComments: number;
  averageShares: number;
  growthRate: number;
  lastUpdated: Date;
}

export interface PlatformSyncSettings {
  autoSync: boolean;
  syncFrequency: 'realtime' | 'hourly' | 'daily' | 'manual';
  syncFields: string[]; // Which fields to sync
  conflictResolution: 'latest' | 'manual' | 'platform_priority';
  privacyLevel: 'public' | 'limited' | 'private';
}

export interface ContentCredential {
  id: string;
  contentHash: string; // SHA-256 hash of content
  contentType: 'image' | 'video' | 'audio' | 'text';
  
  // C2PA standard integration
  c2paManifest: C2PAManifest;
  
  // Creation proof
  createdAt: Date;
  creatorId: string;
  originalPlatform: string;
  
  // Authenticity verification
  authenticityProof: AuthenticityProof;
  verificationStatus: 'verified' | 'pending' | 'disputed' | 'fake';
  
  // Blockchain anchoring
  blockchainTxHash?: string;
  ipfsHash?: string;
}

export interface C2PAManifest {
  version: string;
  claim: {
    generator: string;
    created: string;
    credentials: CreatorCredential[];
    assertions: ContentAssertion[];
  };
  signature: string;
}

export interface CreatorCredential {
  type: 'identity' | 'creation' | 'editing';
  issuer: string;
  validFrom: Date;
  validTo?: Date;
  data: Record<string, any>;
}

export interface ContentAssertion {
  type: 'creation' | 'editing' | 'ai_generation' | 'deepfake_detection';
  confidence: number;
  evidence: Record<string, any>;
  timestamp: Date;
}

export interface AuthenticityProof {
  biometricMatch: number; // 0-1 confidence
  metadataConsistency: number; // 0-1 score
  deepfakeDetection: DeepfakeAnalysis;
  socialProof: SocialProofData;
  blockchainProof: BlockchainProof;
  
  // Overall authenticity score
  overallScore: number; // 0-100
  riskLevel: 'low' | 'medium' | 'high';
}

export interface DeepfakeAnalysis {
  isDeepfake: boolean;
  confidence: number;
  detectionMethods: string[];
  artifacts: DetectedArtifact[];
  modelVersion: string;
  processedAt: Date;
}

export interface DetectedArtifact {
  type: 'temporal_inconsistency' | 'facial_artifacts' | 'lighting_inconsistency' | 'compression_artifacts';
  location: BoundingBox;
  severity: number;
  description: string;
}

export interface BoundingBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface SocialProofData {
  platformVerification: boolean;
  communityVouching: number; // Number of community verifications
  historicalConsistency: number; // Consistency with creator's historical content
  crossPlatformConsistency: number; // Consistency across platforms
}

export interface BlockchainProof {
  transactionHash: string;
  blockNumber: number;
  contractAddress: string;
  timestamp: Date;
  gasUsed: number;
  confirmations: number;
}

// Identity creation and management
export interface CreateIdentityRequest {
  biometricData: BiometricData;
  walletAddress: string;
  initialPlatforms?: PlatformConnectionRequest[];
  privacySettings: PrivacySettings;
}

export interface BiometricData {
  type: 'face' | 'voice' | 'combined';
  encodedData: string; // Base64 encoded biometric features
  confidence: number;
  capturedAt: Date;
  deviceInfo: DeviceInfo;
}

export interface DeviceInfo {
  deviceId: string;
  platform: string;
  osVersion: string;
  appVersion: string;
  securityLevel: 'high' | 'medium' | 'low';
}

export interface PlatformConnectionRequest {
  platformId: string;
  authorizationCode: string;
  redirectUri: string;
}

export interface PrivacySettings {
  publicProfile: boolean;
  shareMetrics: boolean;
  allowDiscovery: boolean;
  dataRetention: number; // Days
  crossPlatformSync: boolean;
  biometricDataSharing: boolean;
}

// Response types
export interface CreateIdentityResponse {
  identity: UniversalCreativeID;
  blockchain: {
    transactionHash: string;
    contractAddress: string;
  };
  qrCode: string; // QR code for identity sharing
  backupCodes: string[]; // Recovery codes
}

export interface VerifyIdentityRequest {
  identityId: string;
  biometricChallenge: string;
  platformProof?: PlatformProof;
}

export interface PlatformProof {
  platformId: string;
  proof: string; // Platform-specific proof of ownership
  timestamp: Date;
}

export interface VerifyIdentityResponse {
  verified: boolean;
  confidence: number;
  verificationLevel: number;
  newBadges?: VerificationBadge[];
}

export interface VerificationBadge {
  id: string;
  type: 'platform_verified' | 'biometric_verified' | 'community_trusted' | 'authenticity_guardian';
  name: string;
  description: string;
  iconUrl: string;
  earnedAt: Date;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
}

// Sync and update types
export interface SyncIdentityRequest {
  identityId: string;
  platforms?: string[]; // Specific platforms to sync, if empty sync all
  forceSync?: boolean; // Force sync even if recently synced
}

export interface SyncIdentityResponse {
  success: boolean;
  syncedPlatforms: string[];
  conflicts: SyncConflict[];
  updatedFields: string[];
  newContent: ContentCredential[];
}

export interface SyncConflict {
  field: string;
  platformValues: Record<string, any>;
  resolution: 'auto' | 'manual_required';
  recommendedAction: string;
}

// Search and discovery types
export interface SearchIdentitiesRequest {
  query?: string;
  platforms?: string[];
  verificationLevel?: number; // Minimum verification level
  location?: GeographicLocation;
  niche?: string;
  collaborationOpen?: boolean;
  limit?: number;
  offset?: number;
}

export interface GeographicLocation {
  country: string;
  region?: string;
  city?: string;
  coordinates?: {
    latitude: number;
    longitude: number;
  };
}

export interface SearchIdentitiesResponse {
  identities: PublicIdentityProfile[];
  total: number;
  hasMore: boolean;
  nextOffset?: number;
}

export interface PublicIdentityProfile {
  id: string;
  displayName: string;
  bio: string;
  avatarUrl: string;
  verificationLevel: number;
  verificationBadges: VerificationBadge[];
  
  // Aggregated platform data (privacy-respecting)
  totalFollowers: number;
  primaryPlatforms: string[];
  contentTypes: string[];
  niche: string[];
  
  // Collaboration info
  openToCollaboration: boolean;
  collaborationTypes: string[];
  
  // Authenticity indicators
  authenticityScore: number;
  contentVerified: number; // Number of verified content pieces
  
  // Location (if public)
  location?: GeographicLocation;
}