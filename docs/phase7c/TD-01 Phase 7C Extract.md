# TD-01 Technology Stack Decisions — Phase 7C Extract (TD-01v.a4)
Sections: §2.9 Schema Version Gating, §3.3 Token Lifecycle During Offline Periods
============================================================

## §2.9 Schema Version Gating

2.9 Schema Version Gating

Sync requires matching schema versions between the device’s local database and the server’s current canonical schema (Section 17, §17.4.9).

-   If a device’s local schema version is older than the server’s current canonical schema, sync is blocked.

-   A clear message is displayed: “App update required to sync.”

-   The device continues to function fully offline against its current local schema while awaiting the app update. No data loss. No degradation.

-   On app update, the application runs any required local schema migrations, then sync proceeds normally with a full deterministic rebuild.

-   All schema migrations must preserve backward compatibility of raw execution entities. Data logged under an older schema version must remain valid and interpretable after migration.


## §3.3 Token Lifecycle During Offline Periods

3.3 Token Lifecycle During Offline Periods

When the app is offline, the JWT access token will eventually expire. On reconnection:

-   The Supabase client SDK automatically attempts to refresh the token using the stored refresh token.

-   If the refresh token is still valid, a new access token is issued silently. Sync proceeds normally.

-   If the refresh token has also expired (extended offline period), the user is prompted to re-authenticate via Google Sign-In. No local data is lost — the app continues to function offline until authentication is restored, at which point queued sync operations execute.

