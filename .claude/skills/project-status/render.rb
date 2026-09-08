#!/usr/bin/env ruby
# Renders PROJECT_STATUS.md to a styled HTML page for viewing in a browser.
# Markdown stays the single source of truth; this output is regenerated each run.

require 'cgi'

SRC = File.expand_path('/Users/john/Projects/lester/PROJECT_STATUS.md')
OUT = File.expand_path('/Users/john/Projects/lester/PROJECT_STATUS.html')

def inline(text)
  text = CGI.escapeHTML(text)
  text = text.gsub(/`([^`]+)`/, '<code>\1</code>')
  text.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
end

PILLS = {
  'in-progress'             => { label: 'In progress',           class: 'pill-blue'   },
  'waiting-on-verification' => { label: 'Waiting on verification', class: 'pill-amber' },
  'investigating'           => { label: 'Investigating',         class: 'pill-purple' },
  'designed'                => { label: 'Designed',              class: 'pill-gray'   },
  'not-started'             => { label: 'Not started',           class: 'pill-red'    },
  'blocked'                 => { label: 'Blocked',               class: 'pill-red'    },
}.freeze

def extract_pill(body)
  if body =~ /^\{([\w-]+)\}\s*/
    tag = $1
    rest = body.sub(/^\{[\w-]+\}\s*/, '')
    [PILLS[tag], rest]
  else
    [nil, body]
  end
end

def pill_html(pill, checked)
  if checked
    '<span class="pill pill-green">Complete</span>'
  elsif pill
    "<span class=\"pill #{pill[:class]}\">#{pill[:label]}</span>"
  else
    ''
  end
end

def render_sections(lines)
  sections = []
  current = nil

  lines.each do |line|
    case line
    when /^## (.+)/
      current = { title: $1.strip, items: [] }
      sections << current
    when /^- \[( |x)\] (.+)/
      next unless current
      checked = $1 == 'x'
      body = $2.strip
      current[:items] << { checked: checked, lines: [body] }
    when /^\s{4,}(\S.+)/
      next unless current && current[:items].any?
      current[:items].last[:lines] << $1.strip
    end
  end

  sections
end

raw = File.read(SRC)
lines = raw.lines.map(&:chomp)

title_line = lines.find { |l| l.start_with?('# ') }
title = title_line ? title_line.sub(/^# /, '') : 'Project Status'

intro_lines = []
lines.each do |l|
  break if l.start_with?('## ')
  next if l.start_with?('# ') || l.strip.empty?
  intro_lines << l
end

sections = render_sections(lines)

section_html = sections.map do |s|
  total = s[:items].size
  done = s[:items].count { |i| i[:checked] }
  pct = total.zero? ? 0 : (done * 100.0 / total).round

  items_html = s[:items].map do |item|
    raw_body, *detail = item[:lines]
    pill, body = extract_pill(raw_body)
    detail_html = detail.empty? ? '' : "<div class=\"detail\">#{inline(detail.join(' '))}</div>"
    <<~ITEM
      <li class="item #{item[:checked] ? 'done' : ''}">
        <span class="box">#{item[:checked] ? '&#9745;' : '&#9744;'}</span>
        <div class="body">
          <div class="headline-row">
            <div class="headline">#{inline(body)}</div>
            #{pill_html(pill, item[:checked])}
          </div>
          #{detail_html}
        </div>
      </li>
    ITEM
  end.join

  progress_html = total.zero? ? '' : <<~PROG
    <div class="progress-track"><div class="progress-fill" style="width:#{pct}%"></div></div>
    <span class="progress-label">#{done}/#{total}</span>
  PROG

  <<~SECTION
    <section class="card">
      <div class="card-header">
        <h2>#{CGI.escapeHTML(s[:title])}</h2>
        <div class="progress">#{progress_html}</div>
      </div>
      <ul class="items">#{items_html}</ul>
    </section>
  SECTION
end.join

generated_at = Time.now.strftime('%-d %b %Y, %H:%M')

html = <<~HTML
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>#{CGI.escapeHTML(title)}</title>
  <style>
    :root {
      --bg: #f6f5f2;
      --card-bg: #ffffff;
      --text: #1f2320;
      --muted: #6b6f6b;
      --border: #e4e1da;
      --accent: #3f6b4f;
      --accent-soft: #d9e8de;
      --done-bg: #f0f5f1;
      --code-bg: #eef0ec;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #17191a;
        --card-bg: #202323;
        --text: #e7e6e2;
        --muted: #9a9d98;
        --border: #33362f;
        --accent: #7cb894;
        --accent-soft: #253730;
        --done-bg: #1c231f;
        --code-bg: #2a2d29;
      }
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 3rem 1.5rem 5rem;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      line-height: 1.5;
    }
    .wrap { max-width: 720px; margin: 0 auto; }
    header { margin-bottom: 2.5rem; }
    h1 { font-size: 1.75rem; margin: 0 0 .5rem; letter-spacing: -0.01em; }
    .intro { color: var(--muted); font-size: .95rem; max-width: 60ch; }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 1.25rem 1.5rem;
      margin-bottom: 1.5rem;
    }
    .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      margin-bottom: .75rem;
    }
    h2 { font-size: 1.05rem; margin: 0; }
    .progress { display: flex; align-items: center; gap: .5rem; min-width: 0; }
    .progress-track {
      width: 80px;
      height: 6px;
      border-radius: 4px;
      background: var(--border);
      overflow: hidden;
      flex-shrink: 0;
    }
    .progress-fill { height: 100%; background: var(--accent); }
    .progress-label { font-size: .8rem; color: var(--muted); white-space: nowrap; }
    ul.items { list-style: none; margin: 0; padding: 0; }
    li.item {
      display: flex;
      gap: .75rem;
      padding: .6rem 0;
      border-top: 1px solid var(--border);
    }
    li.item:first-child { border-top: none; }
    li.item .box { font-size: 1.15rem; line-height: 1.3; color: var(--accent); flex-shrink: 0; }
    li.item.done .box { color: var(--muted); }
    li.item.done .headline { color: var(--muted); text-decoration: line-through; text-decoration-color: var(--border); }
    li.item.done { background: transparent; }
    .headline-row {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: .5rem;
    }
    .headline { font-weight: 600; font-size: .95rem; }
    .detail { color: var(--muted); font-size: .85rem; margin-top: .2rem; }
    .pill {
      display: inline-block;
      font-size: .7rem;
      font-weight: 600;
      letter-spacing: .02em;
      padding: .15rem .55rem;
      border-radius: 999px;
      white-space: nowrap;
      line-height: 1.4;
    }
    .pill-blue   { background: #dce8fb; color: #2451a3; }
    .pill-amber  { background: #fbe8cf; color: #935f10; }
    .pill-purple { background: #e8ddf7; color: #6431a3; }
    .pill-gray   { background: var(--border); color: var(--muted); }
    .pill-red    { background: #fbdcdc; color: #a32424; }
    .pill-green  { background: var(--accent-soft); color: var(--accent); }
    @media (prefers-color-scheme: dark) {
      .pill-blue   { background: #1f3357; color: #9fc0f5; }
      .pill-amber  { background: #4a3512; color: #f0c27b; }
      .pill-purple { background: #362350; color: #cba9f0; }
      .pill-red    { background: #4a1f1f; color: #f0a3a3; }
    }
    code {
      background: var(--code-bg);
      padding: .1rem .35rem;
      border-radius: 4px;
      font-size: .85em;
    }
    footer {
      margin-top: 2.5rem;
      color: var(--muted);
      font-size: .8rem;
      text-align: center;
    }
  </style>
  </head>
  <body>
    <div class="wrap">
      <header>
        <h1>#{CGI.escapeHTML(title)}</h1>
        <div class="intro">#{inline(intro_lines.join(' '))}</div>
      </header>
      #{section_html}
      <footer>Rendered #{generated_at} from PROJECT_STATUS.md &mdash; edit the markdown, re-run to refresh.</footer>
    </div>
  </body>
  </html>
HTML

File.write(OUT, html)
puts OUT
