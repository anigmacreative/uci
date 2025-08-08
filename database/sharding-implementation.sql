-- Creative Identity Platform Database Sharding Implementation
-- Optimized for viral growth scenarios with 10M+ users

-- =====================================================
-- PART 1: Core Tables with Sharding Support
-- =====================================================

-- Identity schema tables (sharded by user_id)
CREATE SCHEMA IF NOT EXISTS identity;

-- User profiles table (main sharded table)
CREATE TABLE identity.user_profiles (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    bio TEXT,
    avatar_url VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active',
    verification_level INTEGER DEFAULT 0,
    last_active TIMESTAMPTZ,
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int) STORED
);

-- Biometric data table (sharded by user_id)
CREATE TABLE identity.biometric_data (
    biometric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    biometric_type VARCHAR(50) NOT NULL, -- 'face', 'fingerprint', 'voice'
    encrypted_template BYTEA NOT NULL,
    confidence_score DECIMAL(3,2),
    device_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int) STORED,
    FOREIGN KEY (user_id) REFERENCES identity.user_profiles(user_id)
);

-- Universal Creative ID registry (sharded by creator_id)
CREATE TABLE identity.creative_identities (
    identity_id VARCHAR(50) PRIMARY KEY, -- Format: uci_xxxxxxxxxx
    user_id UUID NOT NULL UNIQUE,
    blockchain_address VARCHAR(42) NOT NULL UNIQUE,
    story_protocol_id VARCHAR(100),
    authenticity_score DECIMAL(5,2) DEFAULT 0.00,
    verification_badges JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int) STORED,
    FOREIGN KEY (user_id) REFERENCES identity.user_profiles(user_id)
);

-- =====================================================
-- PART 2: Content Schema (sharded by creator_id)
-- =====================================================

CREATE SCHEMA IF NOT EXISTS content;

-- Creator content table (sharded by creator_id)
CREATE TABLE content.creator_content (
    content_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL,
    identity_id VARCHAR(50) NOT NULL,
    content_type VARCHAR(50) NOT NULL, -- 'image', 'video', 'audio', 'text'
    title VARCHAR(500),
    description TEXT,
    content_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 hash
    ipfs_hash VARCHAR(100),
    c2pa_manifest JSONB,
    authenticity_score DECIMAL(5,2) DEFAULT 0.00,
    verification_status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Sharding support  
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(creator_id::text), 1, 8))::bit(32)::int) STORED,
    FOREIGN KEY (creator_id) REFERENCES identity.user_profiles(user_id),
    FOREIGN KEY (identity_id) REFERENCES identity.creative_identities(identity_id)
);

-- Content verification history
CREATE TABLE content.verification_history (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL,
    creator_id UUID NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    provider VARCHAR(100) NOT NULL,
    result JSONB NOT NULL,
    confidence_score DECIMAL(5,2),
    verified_at TIMESTAMPTZ DEFAULT NOW(),
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(creator_id::text), 1, 8))::bit(32)::int) STORED,
    FOREIGN KEY (content_id) REFERENCES content.creator_content(content_id),
    FOREIGN KEY (creator_id) REFERENCES identity.user_profiles(user_id)
);

-- Content licensing and NFTs
CREATE TABLE content.content_licenses (
    license_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL,
    creator_id UUID NOT NULL,
    license_type VARCHAR(50) NOT NULL,
    blockchain_network VARCHAR(50) DEFAULT 'polygon',
    nft_contract_address VARCHAR(42),
    token_id VARCHAR(100),
    transaction_hash VARCHAR(66),
    royalty_percentage DECIMAL(5,2) DEFAULT 10.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(creator_id::text), 1, 8))::bit(32)::int) STORED,
    FOREIGN KEY (content_id) REFERENCES content.creator_content(content_id),
    FOREIGN KEY (creator_id) REFERENCES identity.user_profiles(user_id)
);

-- =====================================================
-- PART 3: Platform Integration Schema (sharded by user_id)
-- =====================================================

CREATE SCHEMA IF NOT EXISTS platforms;

-- Platform connections table (sharded by user_id)
CREATE TABLE platforms.platform_connections (
    connection_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    identity_id VARCHAR(50) NOT NULL,
    platform_id VARCHAR(50) NOT NULL, -- 'tiktok', 'instagram', 'youtube', etc.
    platform_user_id VARCHAR(200) NOT NULL,
    platform_username VARCHAR(200),
    access_token_hash VARCHAR(64), -- Encrypted
    refresh_token_hash VARCHAR(64), -- Encrypted  
    connection_status VARCHAR(20) DEFAULT 'active',
    last_sync TIMESTAMPTZ,
    sync_frequency INTERVAL DEFAULT '1 hour',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int) STORED,
    FOREIGN KEY (user_id) REFERENCES identity.user_profiles(user_id),
    FOREIGN KEY (identity_id) REFERENCES identity.creative_identities(identity_id),
    UNIQUE(user_id, platform_id)
);

-- Platform content sync log (sharded by user_id)
CREATE TABLE platforms.sync_operations (
    sync_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    connection_id UUID NOT NULL,
    user_id UUID NOT NULL,
    operation_type VARCHAR(50) NOT NULL, -- 'import', 'export', 'sync'
    content_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    sync_status VARCHAR(20) DEFAULT 'running',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_details JSONB,
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int) STORED,
    FOREIGN KEY (connection_id) REFERENCES platforms.platform_connections(connection_id),
    FOREIGN KEY (user_id) REFERENCES identity.user_profiles(user_id)
);

-- =====================================================
-- PART 4: Analytics Schema (time-partitioned + sharded)
-- =====================================================

CREATE SCHEMA IF NOT EXISTS analytics;

-- User events table (sharded by user_id AND time-partitioned for viral growth)
CREATE TABLE analytics.user_events (
    event_id UUID DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    identity_id VARCHAR(50),
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL DEFAULT '{}',
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int) STORED,
    PRIMARY KEY (event_id, created_at)
) PARTITION BY RANGE (created_at);

-- Create monthly partitions for the last year and next year
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', NOW() - INTERVAL '12 months');
    end_date DATE := DATE_TRUNC('month', NOW() + INTERVAL '12 months');
    current_date DATE := start_date;
    partition_name TEXT;
BEGIN
    WHILE current_date < end_date LOOP
        partition_name := 'user_events_' || TO_CHAR(current_date, 'YYYY_MM');
        EXECUTE format('CREATE TABLE IF NOT EXISTS analytics.%I PARTITION OF analytics.user_events 
                       FOR VALUES FROM (%L) TO (%L)', 
                       partition_name, current_date, current_date + INTERVAL '1 month');
        current_date := current_date + INTERVAL '1 month';
    END LOOP;
END $$;

-- Enable TimescaleDB hypertable for better time-series performance
SELECT create_hypertable(
    'analytics.user_events',
    'created_at',
    number_partitions => 4,
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Creator metrics aggregation table
CREATE TABLE analytics.creator_metrics_daily (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identity_id VARCHAR(50) NOT NULL,
    user_id UUID NOT NULL,
    date DATE NOT NULL,
    total_content INTEGER DEFAULT 0,
    verified_content INTEGER DEFAULT 0,
    platform_connections INTEGER DEFAULT 0,
    authenticity_score_avg DECIMAL(5,2) DEFAULT 0.00,
    engagement_score DECIMAL(10,2) DEFAULT 0.00,
    earnings_usd DECIMAL(15,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Sharding support
    shard_key INTEGER GENERATED ALWAYS AS (('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int) STORED,
    UNIQUE(identity_id, date)
);

-- =====================================================
-- PART 5: Blockchain Schema (global, non-sharded)
-- =====================================================

CREATE SCHEMA IF NOT EXISTS blockchain;

-- Smart contract registry (global table)
CREATE TABLE blockchain.smart_contracts (
    contract_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_name VARCHAR(100) NOT NULL UNIQUE,
    network VARCHAR(50) NOT NULL, -- 'polygon', 'ethereum', etc.
    contract_address VARCHAR(42) NOT NULL UNIQUE,
    abi JSONB NOT NULL,
    deployment_block BIGINT,
    deployment_tx_hash VARCHAR(66),
    deployed_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active'
);

-- Blockchain transactions log (sharded by user_id)
CREATE TABLE blockchain.transactions (
    tx_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    identity_id VARCHAR(50),
    network VARCHAR(50) NOT NULL,
    tx_hash VARCHAR(66) NOT NULL UNIQUE,
    block_number BIGINT,
    contract_address VARCHAR(42),
    function_name VARCHAR(100),
    gas_used BIGINT,
    gas_price BIGINT,
    tx_fee_wei NUMERIC(30,0),
    tx_fee_usd DECIMAL(15,8),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    -- Sharding support (nullable user_id for system transactions)
    shard_key INTEGER GENERATED ALWAYS AS (
        CASE WHEN user_id IS NOT NULL 
             THEN ('x' || substring(md5(user_id::text), 1, 8))::bit(32)::int
             ELSE 0 -- System transactions go to shard 0
        END
    ) STORED
);

-- =====================================================
-- PART 6: Indexes for Viral Growth Performance
-- =====================================================

-- User profiles indexes
CREATE INDEX idx_user_profiles_email ON identity.user_profiles(email);
CREATE INDEX idx_user_profiles_username ON identity.user_profiles(username);
CREATE INDEX idx_user_profiles_status ON identity.user_profiles(status);
CREATE INDEX idx_user_profiles_last_active ON identity.user_profiles(last_active);
CREATE INDEX idx_user_profiles_shard_key ON identity.user_profiles(shard_key);

-- Biometric data indexes
CREATE INDEX idx_biometric_data_user_id ON identity.biometric_data(user_id);
CREATE INDEX idx_biometric_data_type ON identity.biometric_data(biometric_type);
CREATE INDEX idx_biometric_data_device ON identity.biometric_data(device_id);
CREATE INDEX idx_biometric_data_shard_key ON identity.biometric_data(shard_key);

-- Creative identities indexes
CREATE INDEX idx_creative_identities_user_id ON identity.creative_identities(user_id);
CREATE INDEX idx_creative_identities_blockchain ON identity.creative_identities(blockchain_address);
CREATE INDEX idx_creative_identities_score ON identity.creative_identities(authenticity_score DESC);
CREATE INDEX idx_creative_identities_shard_key ON identity.creative_identities(shard_key);

-- Content indexes
CREATE INDEX idx_creator_content_creator_id ON content.creator_content(creator_id);
CREATE INDEX idx_creator_content_type ON content.creator_content(content_type);
CREATE INDEX idx_creator_content_hash ON content.creator_content(content_hash);
CREATE INDEX idx_creator_content_status ON content.creator_content(verification_status);
CREATE INDEX idx_creator_content_created_at ON content.creator_content(created_at DESC);
CREATE INDEX idx_creator_content_shard_key ON content.creator_content(shard_key);

-- Platform connections indexes
CREATE INDEX idx_platform_connections_user_id ON platforms.platform_connections(user_id);
CREATE INDEX idx_platform_connections_platform ON platforms.platform_connections(platform_id);
CREATE INDEX idx_platform_connections_status ON platforms.platform_connections(connection_status);
CREATE INDEX idx_platform_connections_last_sync ON platforms.platform_connections(last_sync);
CREATE INDEX idx_platform_connections_shard_key ON platforms.platform_connections(shard_key);

-- Analytics indexes (optimized for time-series queries)
CREATE INDEX idx_user_events_user_id_time ON analytics.user_events(user_id, created_at DESC);
CREATE INDEX idx_user_events_event_type_time ON analytics.user_events(event_type, created_at DESC);
CREATE INDEX idx_user_events_session_id ON analytics.user_events(session_id);

-- Creator metrics indexes
CREATE INDEX idx_creator_metrics_identity_date ON analytics.creator_metrics_daily(identity_id, date DESC);
CREATE INDEX idx_creator_metrics_date ON analytics.creator_metrics_daily(date DESC);
CREATE INDEX idx_creator_metrics_score ON analytics.creator_metrics_daily(authenticity_score_avg DESC);
CREATE INDEX idx_creator_metrics_shard_key ON analytics.creator_metrics_daily(shard_key);

-- Blockchain transaction indexes
CREATE INDEX idx_blockchain_tx_user_id ON blockchain.transactions(user_id);
CREATE INDEX idx_blockchain_tx_hash ON blockchain.transactions(tx_hash);
CREATE INDEX idx_blockchain_tx_network ON blockchain.transactions(network);
CREATE INDEX idx_blockchain_tx_status ON blockchain.transactions(status);
CREATE INDEX idx_blockchain_tx_created_at ON blockchain.transactions(created_at DESC);

-- =====================================================
-- PART 7: Functions for Viral Growth Support
-- =====================================================

-- Function to get shard for a given user_id
CREATE OR REPLACE FUNCTION get_user_shard(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN ('x' || substring(md5(user_uuid::text), 1, 8))::bit(32)::int;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to route queries to appropriate shard
CREATE OR REPLACE FUNCTION get_shard_connection(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    shard_key INTEGER;
    shard_name TEXT;
BEGIN
    shard_key := get_user_shard(user_uuid);
    
    -- Determine shard based on hash range
    CASE 
        WHEN shard_key BETWEEN 0 AND 536870911 THEN -- 0x00000000-0x1FFFFFFF
            shard_name := 'shard_01';
        WHEN shard_key BETWEEN 536870912 AND 1073741823 THEN -- 0x20000000-0x3FFFFFFF  
            shard_name := 'shard_02';
        WHEN shard_key BETWEEN 1073741824 AND 1610612735 THEN -- 0x40000000-0x5FFFFFFF
            shard_name := 'shard_03';
        ELSE -- 0x60000000-0x7FFFFFFF
            shard_name := 'shard_04';
    END CASE;
    
    RETURN shard_name;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Trigger function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON identity.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_creative_identities_updated_at
    BEFORE UPDATE ON identity.creative_identities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_creator_content_updated_at
    BEFORE UPDATE ON content.creator_content
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_platform_connections_updated_at
    BEFORE UPDATE ON platforms.platform_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PART 8: Views for Cross-Shard Queries
-- =====================================================

-- Unified view for user profile with identity information
CREATE VIEW identity.user_identity_view AS
SELECT 
    up.user_id,
    up.email,
    up.username,
    up.display_name,
    up.bio,
    up.avatar_url,
    up.status,
    up.verification_level,
    up.created_at AS user_created_at,
    up.last_active,
    ci.identity_id,
    ci.blockchain_address,
    ci.authenticity_score,
    ci.verification_badges,
    ci.created_at AS identity_created_at
FROM identity.user_profiles up
LEFT JOIN identity.creative_identities ci ON up.user_id = ci.user_id;

-- Creator dashboard view with aggregated metrics
CREATE VIEW analytics.creator_dashboard_view AS
SELECT 
    uiv.user_id,
    uiv.identity_id,
    uiv.username,
    uiv.display_name,
    uiv.authenticity_score,
    COUNT(cc.content_id) AS total_content,
    COUNT(CASE WHEN cc.verification_status = 'verified' THEN 1 END) AS verified_content,
    COUNT(DISTINCT pc.platform_id) AS connected_platforms,
    COALESCE(AVG(cc.authenticity_score), 0) AS avg_content_score,
    MAX(cc.created_at) AS last_content_created,
    COUNT(DISTINCT cl.license_id) AS total_licenses
FROM identity.user_identity_view uiv
LEFT JOIN content.creator_content cc ON uiv.user_id = cc.creator_id
LEFT JOIN platforms.platform_connections pc ON uiv.user_id = pc.user_id AND pc.connection_status = 'active'
LEFT JOIN content.content_licenses cl ON cc.content_id = cl.content_id
GROUP BY uiv.user_id, uiv.identity_id, uiv.username, uiv.display_name, uiv.authenticity_score;

-- =====================================================
-- PART 9: Performance Monitoring Queries
-- =====================================================

-- Query to monitor shard distribution
CREATE VIEW monitoring.shard_distribution AS
SELECT 
    CASE 
        WHEN shard_key BETWEEN 0 AND 536870911 THEN 'shard_01'
        WHEN shard_key BETWEEN 536870912 AND 1073741823 THEN 'shard_02'
        WHEN shard_key BETWEEN 1073741824 AND 1610612735 THEN 'shard_03'
        ELSE 'shard_04'
    END AS shard_name,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM identity.user_profiles
GROUP BY 
    CASE 
        WHEN shard_key BETWEEN 0 AND 536870911 THEN 'shard_01'
        WHEN shard_key BETWEEN 536870912 AND 1073741823 THEN 'shard_02'
        WHEN shard_key BETWEEN 1073741824 AND 1610612735 THEN 'shard_03'
        ELSE 'shard_04'
    END;

-- Query to monitor table sizes for capacity planning
CREATE VIEW monitoring.table_sizes AS
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables 
WHERE schemaname IN ('identity', 'content', 'platforms', 'analytics', 'blockchain')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- =====================================================
-- PART 10: Sample Data for Testing Viral Growth
-- =====================================================

-- Insert sample data for testing (remove in production)
-- This creates 1000 sample users distributed across shards
DO $$
DECLARE
    i INTEGER;
    sample_user_id UUID;
    sample_identity_id VARCHAR(50);
BEGIN
    FOR i IN 1..1000 LOOP
        sample_user_id := uuid_generate_v4();
        sample_identity_id := 'uci_' || substr(md5(sample_user_id::text), 1, 10);
        
        INSERT INTO identity.user_profiles (user_id, email, username, display_name, bio)
        VALUES (
            sample_user_id,
            'creator' || i || '@example.com',
            'creator_' || i,
            'Sample Creator ' || i,
            'Sample bio for creator ' || i
        );
        
        INSERT INTO identity.creative_identities (identity_id, user_id, blockchain_address, authenticity_score)
        VALUES (
            sample_identity_id,
            sample_user_id,
            '0x' || substr(md5(sample_user_id::text), 1, 40),
            ROUND((RANDOM() * 100)::numeric, 2)
        );
        
        -- Add some sample content
        IF RANDOM() > 0.3 THEN
            INSERT INTO content.creator_content (creator_id, identity_id, content_type, title, content_hash, authenticity_score)
            VALUES (
                sample_user_id,
                sample_identity_id,
                CASE WHEN RANDOM() > 0.5 THEN 'image' ELSE 'video' END,
                'Sample Content ' || i,
                md5('content_' || i || '_' || sample_user_id::text),
                ROUND((RANDOM() * 100)::numeric, 2)
            );
        END IF;
    END LOOP;
END $$;

COMMIT;

-- =====================================================
-- PART 11: Maintenance and Cleanup Procedures
-- =====================================================

-- Clean up old partitions (run monthly)
CREATE OR REPLACE FUNCTION cleanup_old_partitions()
RETURNS void AS $$
DECLARE
    partition_name TEXT;
    cutoff_date DATE := CURRENT_DATE - INTERVAL '90 days';
BEGIN
    FOR partition_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'analytics' 
        AND tablename LIKE 'user_events_%'
        AND tablename < 'user_events_' || TO_CHAR(cutoff_date, 'YYYY_MM')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS analytics.' || partition_name;
        RAISE NOTICE 'Dropped partition: %', partition_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create new partitions in advance (run monthly)
CREATE OR REPLACE FUNCTION create_future_partitions()
RETURNS void AS $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month');
    end_date DATE := start_date + INTERVAL '12 months';
    current_date DATE := start_date;
    partition_name TEXT;
BEGIN
    WHILE current_date < end_date LOOP
        partition_name := 'user_events_' || TO_CHAR(current_date, 'YYYY_MM');
        BEGIN
            EXECUTE format('CREATE TABLE analytics.%I PARTITION OF analytics.user_events 
                           FOR VALUES FROM (%L) TO (%L)', 
                           partition_name, current_date, current_date + INTERVAL '1 month');
            RAISE NOTICE 'Created partition: %', partition_name;
        EXCEPTION WHEN duplicate_table THEN
            RAISE NOTICE 'Partition % already exists', partition_name;
        END;
        current_date := current_date + INTERVAL '1 month';
    END LOOP;
END;
$$ LANGUAGE plpgsql;