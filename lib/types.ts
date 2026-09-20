export interface Database {
  public: {
    Tables: {
      // ============================================
      // IDENTITY DOMAIN
      // ============================================
      organizations: {
        Row: {
          id: string;
          name: string;
          slug: string;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          slug: string;
          status?: string;
        };
        Update: {
          name?: string;
          slug?: string;
          status?: string;
        };
      };

      users: {
        Row: {
          id: string;
          email: string;
          full_name: string | null;
          avatar_url: string | null;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          full_name?: string;
          avatar_url?: string;
          status?: string;
        };
        Update: {
          email?: string;
          full_name?: string;
          avatar_url?: string;
          status?: string;
        };
      };

      roles: {
        Row: {
          id: string;
          name: string;
          description: string | null;
          is_system: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          description?: string;
          is_system?: boolean;
        };
        Update: {
          name?: string;
          description?: string;
          is_system?: boolean;
        };
      };

      permissions: {
        Row: {
          id: string;
          name: string;
          description: string | null;
          resource: string;
          action: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          description?: string;
          resource: string;
          action: string;
        };
        Update: {
          name?: string;
          description?: string;
          resource?: string;
          action?: string;
        };
      };

      role_permissions: {
        Row: {
          role_id: string;
          permission_id: string;
        };
        Insert: {
          role_id: string;
          permission_id: string;
        };
        Update: Record<string, never>;
      };

      organization_members: {
        Row: {
          id: string;
          organization_id: string;
          user_id: string;
          role_id: string;
          status: string;
          invited_by: string | null;
          joined_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          user_id: string;
          role_id: string;
          status?: string;
          invited_by?: string;
        };
        Update: {
          role_id?: string;
          status?: string;
        };
      };

      // ============================================
      // MARKETPLACE DOMAIN
      // ============================================
      marketplaces: {
        Row: {
          id: string;
          name: string;
          display_name: string;
          api_base_url: string | null;
          logo_url: string | null;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          display_name: string;
          api_base_url?: string;
          logo_url?: string;
          status?: string;
        };
        Update: {
          display_name?: string;
          api_base_url?: string;
          logo_url?: string;
          status?: string;
        };
      };

      marketplace_accounts: {
        Row: {
          id: string;
          organization_id: string;
          marketplace_id: string;
          account_name: string;
          account_id: string;
          status: string;
          last_sync_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          marketplace_id: string;
          account_name: string;
          account_id: string;
          status?: string;
          last_sync_at?: string;
        };
        Update: {
          account_name?: string;
          status?: string;
          last_sync_at?: string;
        };
      };

      marketplace_credentials: {
        Row: {
          id: string;
          marketplace_account_id: string;
          encrypted_data: ArrayBuffer;
          encryption_key_id: string;
          expires_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Record<string, never>;
        Update: Record<string, never>;
      };

      // ============================================
      // PRODUCTS DOMAIN
      // ============================================
      categories: {
        Row: {
          id: string;
          name: string;
          parent_id: string | null;
          marketplace_id: string | null;
          external_id: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          parent_id?: string;
          marketplace_id?: string;
          external_id?: string;
        };
        Update: {
          name?: string;
          parent_id?: string;
          external_id?: string;
        };
      };

      brands: {
        Row: {
          id: string;
          name: string;
          logo_url: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          logo_url?: string;
        };
        Update: {
          name?: string;
          logo_url?: string;
        };
      };

      sellers: {
        Row: {
          id: string;
          marketplace_id: string;
          external_id: string;
          name: string | null;
          reputation_score: number | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          marketplace_id: string;
          external_id: string;
          name?: string;
          reputation_score?: number;
        };
        Update: {
          name?: string;
          reputation_score?: number;
        };
      };

      products: {
        Row: {
          id: string;
          organization_id: string;
          brand_id: string | null;
          name: string;
          description: string | null;
          sku: string | null;
          ean: string | null;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          brand_id?: string;
          name: string;
          description?: string;
          sku?: string;
          ean?: string;
          status?: string;
        };
        Update: {
          brand_id?: string;
          name?: string;
          description?: string;
          sku?: string;
          ean?: string;
          status?: string;
        };
      };

      product_listings: {
        Row: {
          id: string;
          organization_id: string;
          product_id: string;
          marketplace_id: string;
          marketplace_account_id: string;
          seller_id: string | null;
          category_id: string | null;
          external_id: string;
          external_url: string | null;
          title: string | null;
          price_cents: number | null;
          currency: string;
          status: string;
          raw_data: Record<string, unknown> | null;
          collected_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          product_id: string;
          marketplace_id: string;
          marketplace_account_id: string;
          seller_id?: string;
          category_id?: string;
          external_id: string;
          external_url?: string;
          title?: string;
          price_cents?: number;
          currency?: string;
          status?: string;
          raw_data?: Record<string, unknown>;
          collected_at?: string;
        };
        Update: {
          seller_id?: string;
          category_id?: string;
          title?: string;
          price_cents?: number;
          currency?: string;
          status?: string;
          raw_data?: Record<string, unknown>;
          collected_at?: string;
        };
      };

      // ============================================
      // RESEARCH DOMAIN
      // ============================================
      keywords: {
        Row: {
          id: string;
          organization_id: string;
          keyword: string;
          marketplace_id: string;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          keyword: string;
          marketplace_id: string;
          status?: string;
        };
        Update: {
          keyword?: string;
          status?: string;
        };
      };

      searches: {
        Row: {
          id: string;
          organization_id: string;
          keyword_id: string;
          marketplace_id: string;
          marketplace_account_id: string;
          search_term: string;
          status: string;
          executed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          keyword_id: string;
          marketplace_id: string;
          marketplace_account_id: string;
          search_term: string;
          status?: string;
          executed_at?: string;
        };
        Update: {
          status?: string;
          executed_at?: string;
        };
      };

      search_results: {
        Row: {
          id: string;
          search_id: string;
          organization_id: string;
          product_listing_id: string | null;
          position: number | null;
          external_id: string | null;
          title: string | null;
          price_cents: number | null;
          currency: string;
          seller_name: string | null;
          raw_data: Record<string, unknown> | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          search_id: string;
          organization_id: string;
          product_listing_id?: string;
          position?: number;
          external_id?: string;
          title?: string;
          price_cents?: number;
          currency?: string;
          seller_name?: string;
          raw_data?: Record<string, unknown>;
        };
        Update: Record<string, never>;
      };

      // ============================================
      // HISTORICAL DOMAIN
      // ============================================
      price_history: {
        Row: {
          id: string;
          organization_id: string;
          product_listing_id: string;
          price_cents: number;
          currency: string;
          recorded_at: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          product_listing_id: string;
          price_cents: number;
          currency?: string;
          recorded_at: string;
        };
        Update: Record<string, never>;
      };

      metrics_history: {
        Row: {
          id: string;
          organization_id: string;
          entity_type: string;
          entity_id: string;
          metric_name: string;
          metric_value: number | null;
          recorded_at: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          entity_type: string;
          entity_id: string;
          metric_name: string;
          metric_value?: number;
          recorded_at: string;
        };
        Update: Record<string, never>;
      };

      // ============================================
      // ANALYTICS DOMAIN
      // ============================================
      product_metrics: {
        Row: {
          id: string;
          organization_id: string;
          product_listing_id: string;
          metric_date: string;
          views: number;
          sales: number;
          revenue_cents: number;
          conversion_rate: number | null;
          stock_quantity: number | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          product_listing_id: string;
          metric_date: string;
          views?: number;
          sales?: number;
          revenue_cents?: number;
          conversion_rate?: number;
          stock_quantity?: number;
        };
        Update: {
          views?: number;
          sales?: number;
          revenue_cents?: number;
          conversion_rate?: number;
          stock_quantity?: number;
        };
      };

      market_metrics: {
        Row: {
          id: string;
          organization_id: string;
          marketplace_id: string;
          metric_date: string;
          total_listings: number;
          avg_price_cents: number | null;
          currency: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          marketplace_id: string;
          metric_date: string;
          total_listings?: number;
          avg_price_cents?: number;
          currency?: string;
        };
        Update: {
          total_listings?: number;
          avg_price_cents?: number;
          currency?: string;
        };
      };

      competitor_metrics: {
        Row: {
          id: string;
          organization_id: string;
          seller_id: string;
          marketplace_id: string;
          metric_date: string;
          total_listings: number;
          estimated_sales: number;
          estimated_revenue_cents: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          seller_id: string;
          marketplace_id: string;
          metric_date: string;
          total_listings?: number;
          estimated_sales?: number;
          estimated_revenue_cents?: number;
        };
        Update: {
          total_listings?: number;
          estimated_sales?: number;
          estimated_revenue_cents?: number;
        };
      };

      opportunities: {
        Row: {
          id: string;
          organization_id: string;
          marketplace_id: string;
          product_listing_id: string | null;
          keyword_id: string | null;
          opportunity_type: string;
          description: string | null;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          marketplace_id: string;
          product_listing_id?: string;
          keyword_id?: string;
          opportunity_type: string;
          description?: string;
          status?: string;
        };
        Update: {
          opportunity_type?: string;
          description?: string;
          status?: string;
        };
      };

      opportunity_scores: {
        Row: {
          id: string;
          opportunity_id: string;
          score: number;
          confidence: number | null;
          factors: Record<string, unknown>;
          scored_at: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          opportunity_id: string;
          score: number;
          confidence?: number;
          factors?: Record<string, unknown>;
        };
        Update: {
          score?: number;
          confidence?: number;
          factors?: Record<string, unknown>;
        };
      };

      // ============================================
      // PRICING DOMAIN
      // ============================================
      pricing_scenarios: {
        Row: {
          id: string;
          organization_id: string;
          product_id: string;
          name: string;
          target_price_cents: number | null;
          currency: string;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          product_id: string;
          name: string;
          target_price_cents?: number;
          currency?: string;
          status?: string;
        };
        Update: {
          name?: string;
          target_price_cents?: number;
          status?: string;
        };
      };

      costs: {
        Row: {
          id: string;
          organization_id: string;
          product_id: string;
          cost_type: string;
          amount_cents: number;
          currency: string;
          effective_from: string | null;
          effective_to: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          product_id: string;
          cost_type: string;
          amount_cents: number;
          currency?: string;
          effective_from?: string;
          effective_to?: string;
        };
        Update: {
          cost_type?: string;
          amount_cents?: number;
          currency?: string;
          effective_from?: string;
          effective_to?: string;
        };
      };

      fees: {
        Row: {
          id: string;
          marketplace_id: string;
          fee_type: string;
          fee_percentage: number | null;
          fee_fixed_cents: number | null;
          category_id: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          marketplace_id: string;
          fee_type: string;
          fee_percentage?: number;
          fee_fixed_cents?: number;
          category_id?: string;
        };
        Update: {
          fee_type?: string;
          fee_percentage?: number;
          fee_fixed_cents?: number;
          category_id?: string;
        };
      };

      taxes: {
        Row: {
          id: string;
          organization_id: string;
          tax_name: string;
          tax_percentage: number;
          region: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          tax_name: string;
          tax_percentage: number;
          region?: string;
        };
        Update: {
          tax_name?: string;
          tax_percentage?: number;
          region?: string;
        };
      };

      shipping_costs: {
        Row: {
          id: string;
          organization_id: string;
          marketplace_id: string;
          region: string | null;
          min_days: number | null;
          max_days: number | null;
          cost_cents: number;
          currency: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          marketplace_id: string;
          region?: string;
          min_days?: number;
          max_days?: number;
          cost_cents: number;
          currency?: string;
        };
        Update: {
          region?: string;
          min_days?: number;
          max_days?: number;
          cost_cents?: number;
          currency?: string;
        };
      };

      ad_costs: {
        Row: {
          id: string;
          organization_id: string;
          marketplace_id: string;
          marketplace_account_id: string;
          campaign_name: string | null;
          campaign_id: string | null;
          spend_cents: number;
          currency: string;
          impressions: number;
          clicks: number;
          recorded_at: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          marketplace_id: string;
          marketplace_account_id: string;
          campaign_name?: string;
          campaign_id?: string;
          spend_cents: number;
          currency?: string;
          impressions?: number;
          clicks?: number;
          recorded_at: string;
        };
        Update: {
          campaign_name?: string;
          campaign_id?: string;
          spend_cents?: number;
          impressions?: number;
          clicks?: number;
        };
      };

      // ============================================
      // SYSTEM DOMAIN
      // ============================================
      alerts: {
        Row: {
          id: string;
          organization_id: string;
          alert_type: string;
          severity: string;
          message: string;
          entity_type: string | null;
          entity_id: string | null;
          is_read: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          alert_type: string;
          severity?: string;
          message: string;
          entity_type?: string;
          entity_id?: string;
          is_read?: boolean;
        };
        Update: {
          severity?: string;
          message?: string;
          is_read?: boolean;
        };
      };

      notifications: {
        Row: {
          id: string;
          organization_id: string;
          user_id: string;
          notification_type: string;
          title: string;
          body: string | null;
          is_read: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          user_id: string;
          notification_type: string;
          title: string;
          body?: string;
          is_read?: boolean;
        };
        Update: {
          is_read?: boolean;
        };
      };

      audit_logs: {
        Row: {
          id: string;
          organization_id: string;
          user_id: string | null;
          action: string;
          entity_type: string | null;
          entity_id: string | null;
          metadata: Record<string, unknown>;
          ip_address: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          user_id?: string;
          action: string;
          entity_type?: string;
          entity_id?: string;
          metadata?: Record<string, unknown>;
          ip_address?: string;
        };
        Update: Record<string, never>;
      };

      jobs: {
        Row: {
          id: string;
          organization_id: string;
          job_type: string;
          status: string;
          priority: number;
          payload: Record<string, unknown>;
          result: Record<string, unknown> | null;
          error_message: string | null;
          started_at: string | null;
          completed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          job_type: string;
          status?: string;
          priority?: number;
          payload?: Record<string, unknown>;
          result?: Record<string, unknown>;
          error_message?: string;
          started_at?: string;
          completed_at?: string;
        };
        Update: {
          status?: string;
          priority?: number;
          payload?: Record<string, unknown>;
          result?: Record<string, unknown>;
          error_message?: string;
          started_at?: string;
          completed_at?: string;
        };
      };

      organization_invitations: {
        Row: {
          id: string;
          organization_id: string;
          email: string;
          role_id: string;
          status: string;
          invited_by: string | null;
          token: string;
          expires_at: string;
          accepted_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          email: string;
          role_id: string;
          status?: string;
          invited_by?: string;
          token?: string;
          expires_at?: string;
          accepted_at?: string;
        };
        Update: {
          email?: string;
          role_id?: string;
          status?: string;
          invited_by?: string;
          token?: string;
          expires_at?: string;
          accepted_at?: string;
        };
      };
    };
  };
}

// Domain type exports
export type Organization = Database['public']['Tables']['organizations']['Row'];
export type User = Database['public']['Tables']['users']['Row'];
export type Role = Database['public']['Tables']['roles']['Row'];
export type Permission = Database['public']['Tables']['permissions']['Row'];
export type OrganizationMember = Database['public']['Tables']['organization_members']['Row'];

export type Marketplace = Database['public']['Tables']['marketplaces']['Row'];
export type MarketplaceAccount = Database['public']['Tables']['marketplace_accounts']['Row'];

export type Category = Database['public']['Tables']['categories']['Row'];
export type Brand = Database['public']['Tables']['brands']['Row'];
export type Seller = Database['public']['Tables']['sellers']['Row'];
export type Product = Database['public']['Tables']['products']['Row'];
export type ProductListing = Database['public']['Tables']['product_listings']['Row'];

export type Keyword = Database['public']['Tables']['keywords']['Row'];
export type Search = Database['public']['Tables']['searches']['Row'];
export type SearchResult = Database['public']['Tables']['search_results']['Row'];

export type PriceHistory = Database['public']['Tables']['price_history']['Row'];
export type MetricsHistory = Database['public']['Tables']['metrics_history']['Row'];

export type ProductMetrics = Database['public']['Tables']['product_metrics']['Row'];
export type MarketMetrics = Database['public']['Tables']['market_metrics']['Row'];
export type CompetitorMetrics = Database['public']['Tables']['competitor_metrics']['Row'];
export type Opportunity = Database['public']['Tables']['opportunities']['Row'];
export type OpportunityScore = Database['public']['Tables']['opportunity_scores']['Row'];

export type PricingScenario = Database['public']['Tables']['pricing_scenarios']['Row'];
export type Cost = Database['public']['Tables']['costs']['Row'];
export type Fee = Database['public']['Tables']['fees']['Row'];
export type Tax = Database['public']['Tables']['taxes']['Row'];
export type ShippingCost = Database['public']['Tables']['shipping_costs']['Row'];
export type AdCost = Database['public']['Tables']['ad_costs']['Row'];

export type Alert = Database['public']['Tables']['alerts']['Row'];
export type Notification = Database['public']['Tables']['notifications']['Row'];
export type AuditLog = Database['public']['Tables']['audit_logs']['Row'];
export type Job = Database['public']['Tables']['jobs']['Row'];
