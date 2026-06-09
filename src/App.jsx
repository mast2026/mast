import { useEffect } from "react";
import EtaPromotionApp from "./EtaPromotionApp.jsx";

var VERSION_KEY = "mast_deploy_version_v1";

function useDeployVersionRefresh() {
  useEffect(function() {
    if (import.meta.env.DEV) return;

    var cancelled = false;
    async function checkVersion() {
      try {
        var res = await fetch("/deploy-version.json?t=" + Date.now(), { cache: "no-store" });
        if (!res.ok) return;
        var info = await res.json();
        var nextVersion = info && info.version;
        if (!nextVersion || cancelled) return;

        var currentVersion = localStorage.getItem(VERSION_KEY);
        if (!currentVersion) {
          localStorage.setItem(VERSION_KEY, nextVersion);
          return;
        }
        if (currentVersion === nextVersion) return;

        var reloadKey = "mast_reloaded_for_" + nextVersion;
        localStorage.setItem(VERSION_KEY, nextVersion);
        if (sessionStorage.getItem(reloadKey)) return;
        sessionStorage.setItem(reloadKey, "1");
        window.location.reload();
      } catch {
        // Safari home-screen apps can be picky with cache checks; ignore and keep the app usable.
      }
    }

    checkVersion();
    var timer = window.setInterval(checkVersion, 5 * 60 * 1000);
    return function() {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, []);
}

export default function App() {
  useDeployVersionRefresh();
  return <EtaPromotionApp />;
}
