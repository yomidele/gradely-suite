import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuthSession } from "./use-auth";
import type { Database } from "@/integrations/supabase/types";

export type AppRole = Database["public"]["Enums"] extends { app_role: infer R } ? R : "super_admin" | "faculty_admin" | "student";

export function useRole() {
  const { session, loading: sessionLoading } = useAuthSession();
  const [roles, setRoles] = useState<AppRole[]>([]);
  const [loading, setLoading] = useState(true);
  // Was keyed off the whole `session` object before — Supabase silently
  // refreshes the access token on a timer, which produces a brand-new
  // session object for the SAME user. That made this effect re-run and
  // re-query user_roles on every token refresh, and any transient hiccup in
  // that refetch (network blip, RLS evaluated a beat before the refreshed
  // token settled) would briefly overwrite good roles with an empty array —
  // which is what caused admin dashboards to flicker between content and
  // the loading spinner. Keying off the user id instead means this only
  // re-runs when who's logged in actually changes, not on every silent
  // token refresh.
  const userId = session?.user?.id ?? null;

  useEffect(() => {
    if (sessionLoading) return;
    if (!userId) {
      setRoles([]);
      setLoading(false);
      return;
    }
    let cancelled = false;
    (async () => {
      const { data, error } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", userId);
      if (cancelled) return;
      // Don't overwrite already-known-good roles with an empty array on a
      // failed/errored fetch — that's exactly the kind of transient blip
      // that produced the flicker. Only commit a result we're confident in.
      if (error) {
        console.error("Failed to load user roles:", error.message);
        setLoading(false);
        return;
      }
      setRoles((data ?? []).map((r) => r.role as AppRole));
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [userId, sessionLoading]);

  return {
    roles,
    loading: sessionLoading || loading,
    isSuperAdmin: roles.includes("super_admin" as AppRole),
    isFacultyAdmin: roles.includes("faculty_admin" as AppRole),
    isStudent: roles.includes("student" as AppRole),
  };
}
