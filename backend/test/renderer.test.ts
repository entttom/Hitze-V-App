import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, it } from "node:test";
import { availableCopyLanguages, loadPushCopy, renderPush, resolveCopyLanguage, timeText, type PushDay, type PushEvent } from "../api/cron/renderer";

interface GoldenCase {
  id: string;
  now: string;
  event: PushEvent;
  name: string;
  days: PushDay[];
  expected: Record<string, { title: string; body: string }>;
}

const examples = JSON.parse(
  readFileSync(path.join(__dirname, "..", "assets", "push-copy-examples.json"), "utf8")
) as { cases: GoldenCase[] };

describe("renderer golden vectors (push-copy-examples.json)", () => {
  for (const testCase of examples.cases) {
    for (const language of ["de", "en"]) {
      it(`${testCase.id} [${language}]`, () => {
        const expected = testCase.expected[language];
        assert.ok(expected, `golden vector ${testCase.id} has no ${language} expectation`);
        const rendered = renderPush({
          event: testCase.event,
          name: testCase.name,
          days: testCase.days,
          nowMs: Date.parse(testCase.now),
          language,
        });
        assert.deepEqual(rendered, expected);
      });
    }
  }

  it("covers every language listed in the examples", () => {
    for (const testCase of examples.cases) {
      for (const [language, expected] of Object.entries(testCase.expected)) {
        const rendered = renderPush({
          event: testCase.event,
          name: testCase.name,
          days: testCase.days,
          nowMs: Date.parse(testCase.now),
          language,
        });
        assert.deepEqual(rendered, expected, `${testCase.id} [${language}]`);
      }
    }
  });
});

describe("renderer for every language in push-copy.json", () => {
  for (const language of availableCopyLanguages()) {
    it(`renders all cases without throwing [${language}]`, () => {
      for (const testCase of examples.cases) {
        const rendered = renderPush({
          event: testCase.event,
          name: testCase.name,
          days: testCase.days,
          nowMs: Date.parse(testCase.now),
          language,
        });
        assert.ok(rendered.title.length > 0);
        assert.ok(rendered.body.includes(testCase.name), `${language}/${testCase.id} body lacks the name`);
        assert.doesNotMatch(rendered.title + rendered.body, /\{[a-zA-Z0-9]+\}/, `${language}/${testCase.id} has an unreplaced placeholder`);
        assert.doesNotMatch(rendered.body, /Heat-V/);
      }
    });
  }
});

describe("renderer fallbacks", () => {
  it("unknown language falls back to fallbackLanguage", () => {
    const copy = loadPushCopy();
    const rendered = renderPush({ event: "test", name: "Graz", days: [], nowMs: 0, language: "xx" });
    const fallback = resolveCopyLanguage(copy, copy.fallbackLanguage);
    assert.equal(rendered.title, fallback.titleTest);
  });

  it("partial language borrows missing keys from the fallback", () => {
    const copy = loadPushCopy();
    const partial = { ...copy, languages: { ...copy.languages, zz: { title: "ZZ" } } };
    const rendered = renderPush(
      {
        event: "new",
        name: "Graz",
        days: [{ date: "2026-07-07", level: 3, start: "", end: "" }],
        nowMs: Date.parse("2026-07-07T06:30:00Z"),
        language: "zz",
      },
      partial
    );
    assert.equal(rendered.title, "ZZ");
    assert.match(rendered.body, /Graz/);
  });

  it("times are Europe/Vienna HH:mm also in winter (CET)", () => {
    const copy = resolveCopyLanguage(loadPushCopy(), "en");
    assert.equal(
      timeText(copy, { date: "2026-03-07", level: 3, start: "2026-03-07T13:00:00Z", end: "2026-03-07T17:00:00Z" }),
      "14:00–18:00"
    );
  });

  it("end at 23:59 is not all day; end at next midnight is", () => {
    const copy = resolveCopyLanguage(loadPushCopy(), "en");
    assert.equal(
      timeText(copy, { date: "2026-07-07", level: 2, start: "2026-07-06T22:00:00Z", end: "2026-07-07T21:59:00Z" }),
      "00:00–23:59"
    );
    assert.equal(
      timeText(copy, { date: "2026-07-07", level: 2, start: "", end: "" }),
      "all day"
    );
  });
});
