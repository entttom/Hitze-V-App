import { readFileSync } from "node:fs";
import path from "node:path";
import { assetsDir } from "./env";

export interface MunicipalityOption {
  municipalityId: string;
  name: string;
}

let nameById: Map<string, string> | null = null;

/** Same normalisation as the apps: `String(value).replace(/\s+/g, "")`. */
export function normalizeGkz(value: unknown): string {
  return String(value).replace(/\s+/g, "");
}

/** Collapses whitespace and puts exactly one space after each comma ("Wien  1.,Innere Stadt" -> "Wien 1., Innere Stadt"). */
export function normalizeMunicipalityName(value: string): string {
  return value.replace(/\s*,\s*/g, ", ").replace(/\s+/g, " ").trim();
}

function loadNames(): Map<string, string> {
  if (nameById) {
    return nameById;
  }

  const map = new Map<string, string>();
  try {
    const raw = JSON.parse(readFileSync(path.join(assetsDir(), "municipalities.json"), "utf8")) as {
      municipalities?: Record<string, unknown>;
    };
    for (const [id, name] of Object.entries(raw.municipalities ?? {})) {
      if (typeof name === "string" && name.trim()) {
        map.set(normalizeGkz(id), normalizeMunicipalityName(name));
      }
    }
  } catch (error) {
    console.error("municipality_list_load_failed", {
      error: error instanceof Error ? error.message : String(error),
    });
  }

  nameById = map;
  return map;
}

export function municipalityName(gkz: string): string {
  return loadNames().get(gkz) ?? `Gemeinde ${gkz}`;
}

export function hasMunicipality(gkz: string): boolean {
  return loadNames().has(gkz);
}

export function listMunicipalities(): MunicipalityOption[] {
  return Array.from(loadNames(), ([municipalityId, name]) => ({ municipalityId, name })).sort((a, b) =>
    a.municipalityId.localeCompare(b.municipalityId)
  );
}
