import type { Extension } from "@codemirror/state"
import type { Language } from "@codemirror/language"
import { HighlightStyle, syntaxHighlighting } from "@codemirror/language"
import {
  jsxLanguage,
  javascriptLanguage,
  tsxLanguage,
  typescriptLanguage,
} from "@codemirror/lang-javascript"
import { markdownLanguage } from "@codemirror/lang-markdown"
import { pythonLanguage } from "@codemirror/lang-python"
import { jsonLanguage } from "@codemirror/lang-json"
import { cppLanguage } from "@codemirror/lang-cpp"
import { cssLanguage } from "@codemirror/lang-css"
import { htmlLanguage } from "@codemirror/lang-html"
import { xmlLanguage } from "@codemirror/lang-xml"
import { yamlLanguage } from "@codemirror/lang-yaml"
import { rustLanguage } from "@codemirror/lang-rust"
import { phpLanguage } from "@codemirror/lang-php"
import { javaLanguage } from "@codemirror/lang-java"
import { goLanguage } from "@codemirror/lang-go"
import {
  Cassandra,
  MSSQL,
  MariaSQL,
  MySQL,
  PLSQL,
  PostgreSQL,
  SQLite,
  StandardSQL,
  sql,
} from "@codemirror/lang-sql"
import { sass, sassLanguage } from "@codemirror/lang-sass"
import { lessLanguage } from "@codemirror/lang-less"
import { liquidLanguage } from "@codemirror/lang-liquid"
import { wastLanguage } from "@codemirror/lang-wast"
import { jinjaLanguage } from "@codemirror/lang-jinja"
import { vueLanguage } from "@codemirror/lang-vue"
import { angularLanguage } from "@codemirror/lang-angular"
import { tags as t } from "@lezer/highlight"

/**
 * Monospace for fenced editors that `@codemirror/language-data` can attach to Markdown ` ``` ` fences.
 *
 * Covers every `@codemirror/lang-*` import used by language-data:
 * cpp, css, go, html, java, javascript (four configs), jinja, json, less, liquid, php, python, rust,
 * sass SCSS + indented Sass (two distinct parsers), vue, angular, wast, xml, yaml, sql dialects.
 * Nested ` ```markdown ` reuses Markdown as the outer host; monospace for code there still comes from
 * `markdownCodeFontFaces()` (`tags.monospace`), not `all` scoped to `markdownLanguage` (that would monospace the whole document).
 *
 * Entries that load only `@codemirror/legacy-modes/mode/*` (StreamLanguage) are omitted here—they need
 * a separate pass if we want monospace in those fences (~80 parsers; dynamic load only).
 */

const sassIndentedLanguage = sass({ indented: true }).language

/** System mono stack — only for fenced / inline code, not prose. */
const CODE_FONT_FAMILY =
  'ui-monospace, "SF Mono", Menlo, Monaco, SFMono-Regular, Consolas, "Liberation Mono", monospace'

/**
 * Scoped to Markdown-only `monospace` nodes (``, plain fenced/indented chunks).
 * Does not wrap whole documents; fenced languages get their own scope below.
 */
export function markdownCodeFontFaces(): Extension {
  return syntaxHighlighting(
    HighlightStyle.define(
      [
        {
          tag: t.monospace,
          fontFamily: CODE_FONT_FAMILY,
          fontSize: "0.92em",
        },
      ],
      { scope: markdownLanguage }
    )
  )
}

function monospaceProgrammingScope(scope: Language): Extension {
  return syntaxHighlighting(
    HighlightStyle.define([], {
      scope,
      all: { fontFamily: CODE_FONT_FAMILY, fontSize: "0.93em" },
    })
  )
}

const SQL_DIALECTS = [
  StandardSQL,
  PostgreSQL,
  MySQL,
  SQLite,
  MariaSQL,
  Cassandra,
  MSSQL,
  PLSQL,
] as const

const EMBEDDED_CODE_LANGUAGES: readonly Language[] = [
  javascriptLanguage,
  typescriptLanguage,
  jsxLanguage,
  tsxLanguage,
  pythonLanguage,
  jsonLanguage,
  cppLanguage,
  cssLanguage,
  htmlLanguage,
  xmlLanguage,
  yamlLanguage,
  rustLanguage,
  phpLanguage,
  javaLanguage,
  goLanguage,
  sassLanguage,
  sassIndentedLanguage,
  lessLanguage,
  liquidLanguage,
  wastLanguage,
  jinjaLanguage,
  vueLanguage,
  angularLanguage,
  ...SQL_DIALECTS.map((d) => sql({ dialect: d }).language),
]

/** Builds `syntaxHighlighting` facets so monospace applies only inside each embedded `Language`; token colors remain from CM. */
export function embeddedCodeFontFaces(): Extension[] {
  return EMBEDDED_CODE_LANGUAGES.map(monospaceProgrammingScope)
}
