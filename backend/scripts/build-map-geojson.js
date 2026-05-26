const { mkdir, readFile, writeFile } = require("node:fs/promises");
const path = require("node:path");

const DATASET_DATE = "20260101";
const DATASETS = [
  {
    kind: "district",
    typeName: "GEODATA:STATISTIK_AUSTRIA_POLBEZ_20260101",
    outputFile: `political-districts-${DATASET_DATE}.geojson`,
    outputName: `STATISTIK_AUSTRIA_POLBEZ_${DATASET_DATE}`,
    sourceTitle: "Statistik Austria politische Bezirke",
    simplifyToleranceMeters: 150,
  },
  {
    kind: "municipality",
    typeName: "GEODATA:STATISTIK_AUSTRIA_GEM_20260101",
    outputFile: `municipalities-${DATASET_DATE}.geojson`,
    outputName: `STATISTIK_AUSTRIA_GEM_${DATASET_DATE}`,
    sourceTitle: "Statistik Austria Gemeinden",
    simplifyToleranceMeters: 180,
  },
];

function wfsUrl(typeName) {
  return (
    "https://www.statistik.gv.at/gs-open/GEODATA/ows" +
    "?service=WFS" +
    "&version=1.0.0" +
    "&request=GetFeature" +
    "&typeName=" +
    encodeURIComponent(typeName) +
    "&outputFormat=application/json" +
    "&srsName=EPSG:31287"
  );
}

function outputPath(outputFile) {
  return path.resolve(__dirname, "..", "dist", "assets", outputFile);
}

function squaredDistance(a, b) {
  const dx = a[0] - b[0];
  const dy = a[1] - b[1];
  return dx * dx + dy * dy;
}

function squaredSegmentDistance(point, start, end) {
  let x = start[0];
  let y = start[1];
  const dx = end[0] - x;
  const dy = end[1] - y;

  if (dx !== 0 || dy !== 0) {
    const t = ((point[0] - x) * dx + (point[1] - y) * dy) / (dx * dx + dy * dy);
    if (t > 1) {
      x = end[0];
      y = end[1];
    } else if (t > 0) {
      x += dx * t;
      y += dy * t;
    }
  }

  return squaredDistance(point, [x, y]);
}

function simplifyLine(points, tolerance) {
  if (points.length <= 2) return points;

  const sqTolerance = tolerance * tolerance;
  const markers = new Uint8Array(points.length);
  const stack = [[0, points.length - 1]];
  markers[0] = 1;
  markers[points.length - 1] = 1;

  while (stack.length > 0) {
    const [first, last] = stack.pop();
    let maxSqDistance = 0;
    let index = 0;

    for (let i = first + 1; i < last; i += 1) {
      const sqDistance = squaredSegmentDistance(points[i], points[first], points[last]);
      if (sqDistance > maxSqDistance) {
        index = i;
        maxSqDistance = sqDistance;
      }
    }

    if (maxSqDistance > sqTolerance) {
      markers[index] = 1;
      stack.push([first, index], [index, last]);
    }
  }

  return points.filter((_, index) => markers[index]);
}

function roundPoint(point) {
  return [Math.round(Number(point[0])), Math.round(Number(point[1]))];
}

function simplifyRing(ring, tolerance) {
  if (!Array.isArray(ring) || ring.length < 4) return null;

  const rounded = ring
    .filter((point) => Array.isArray(point) && point.length >= 2)
    .map(roundPoint);

  if (rounded.length < 4) return null;

  const openRing =
    squaredDistance(rounded[0], rounded[rounded.length - 1]) === 0
      ? rounded.slice(0, -1)
      : rounded;
  const simplified = simplifyLine(openRing, tolerance);
  if (simplified.length < 3) return null;

  return [...simplified, simplified[0]];
}

function simplifyGeometry(geometry, tolerance) {
  if (!geometry || typeof geometry !== "object" || !Array.isArray(geometry.coordinates)) {
    return geometry;
  }

  if (geometry.type === "Polygon") {
    const coordinates = geometry.coordinates.map((ring) => simplifyRing(ring, tolerance)).filter(Boolean);
    return coordinates.length > 0 ? { type: "Polygon", coordinates } : geometry;
  }

  if (geometry.type === "MultiPolygon") {
    const coordinates = geometry.coordinates
      .map((polygon) =>
        Array.isArray(polygon)
          ? polygon.map((ring) => simplifyRing(ring, tolerance)).filter(Boolean)
          : []
      )
      .filter((polygon) => polygon.length > 0);
    return coordinates.length > 0 ? { type: "MultiPolygon", coordinates } : geometry;
  }

  return geometry;
}

function normalizeFeature(feature, dataset) {
  const properties = feature && typeof feature.properties === "object" ? feature.properties : {};
  const id = String(properties.g_id ?? "").trim();
  const name = String(properties.g_name ?? "").trim();

  if (!id || !name || !feature.geometry) return null;

  return {
    type: "Feature",
    id,
    properties: {
      id,
      name,
    },
    geometry: simplifyGeometry(feature.geometry, dataset.simplifyToleranceMeters),
  };
}

async function readExistingOutput(filePath) {
  try {
    return await readFile(filePath, "utf8");
  } catch {
    return null;
  }
}

async function buildDataset(dataset) {
  const url = wfsUrl(dataset.typeName);
  const filePath = outputPath(dataset.outputFile);
  let payload;

  try {
    const response = await fetch(url, { headers: { Accept: "application/json" } });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    payload = await response.json();
  } catch (error) {
    const existing = await readExistingOutput(filePath);
    if (existing) {
      console.warn(
        `${dataset.kind}_geojson_fetch_failed_using_existing: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
      return;
    }

    throw error;
  }

  if (!payload || payload.type !== "FeatureCollection" || !Array.isArray(payload.features)) {
    throw new Error(`${dataset.kind} WFS response is not a GeoJSON FeatureCollection.`);
  }

  const features = payload.features
    .map((feature) => normalizeFeature(feature, dataset))
    .filter(Boolean);
  if (features.length === 0) {
    throw new Error(`${dataset.kind} WFS response does not contain usable features.`);
  }

  const output = {
    type: "FeatureCollection",
    name: dataset.outputName,
    crs: {
      type: "name",
      properties: { name: "EPSG:31287" },
    },
    source: {
      title: dataset.sourceTitle,
      url,
      license: "CC BY 4.0",
      datasetDate: DATASET_DATE,
      simplifyToleranceMeters: dataset.simplifyToleranceMeters,
      generatedAt: new Date().toISOString(),
    },
    features,
  };

  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, JSON.stringify(output), "utf8");
  console.log(`${dataset.kind}_geojson_written ${filePath} features=${features.length}`);
}

async function main() {
  for (const dataset of DATASETS) {
    await buildDataset(dataset);
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
