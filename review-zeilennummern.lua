-- Review-Fassung: fortlaufende, feste Nummern für Überschriften, Absätze,
-- Listenpunkte, Tabellenzeilen und HTML-Blöcke. Die Nummern stehen im HTML
-- (data-z, id="zN"); review-zeilennummern.js stellt sie in die Randspalte.

local n = 0
local skip = { ["review-kopf"] = true, ["review-technik"] = true }

local function attr()
  n = n + 1
  return pandoc.Attr("z" .. n, { "zn" }, { { "data-z", tostring(n) } })
end

local function marke()
  return pandoc.Span({}, attr())
end

local function block_marke(el)
  return pandoc.Div({ el }, attr())
end

local function zeile(row)
  local leer = true
  for _, c in ipairs(row.cells) do
    if #c.contents > 0 then leer = false end
  end
  if leer then return row end
  local c = row.cells[1]
  local first = c.contents[1]
  if first and (first.t == "Plain" or first.t == "Para") then
    first.content:insert(1, marke())
    c.contents[1] = first
  else
    c.contents:insert(1, pandoc.Plain({ marke() }))
  end
  row.cells[1] = c
  return row
end

local function zeilen(rows)
  for i, r in ipairs(rows) do rows[i] = zeile(r) end
  return rows
end

local function inline_marke(el)
  el.content:insert(1, marke())
  return el, false
end

local filter = {
  traverse = "topdown",
  Div = function(el)
    -- Quarto legt Navigation und Fusszeile in versteckte quarto-*-Container
    if el.identifier:match("^quarto%-") then return el, false end
    for _, c in ipairs(el.classes) do
      if skip[c] then return el, false end
    end
  end,
  Header = inline_marke,
  Para = inline_marke,
  Plain = inline_marke,
  Figure = function(el) return block_marke(el), false end,
  RawBlock = function(el)
    if el.format == "html" then return block_marke(el), false end
  end,
  Table = function(tbl)
    tbl.head.rows = zeilen(tbl.head.rows)
    for i, b in ipairs(tbl.bodies) do
      b.head = zeilen(b.head)
      b.body = zeilen(b.body)
      tbl.bodies[i] = b
    end
    tbl.foot.rows = zeilen(tbl.foot.rows)
    return tbl, false
  end,
}

-- Nur der Dokumentkörper, nicht Titel, Navigation oder Fusszeile. Quarto rendert
-- die Fusszeile in einem eigenen Durchlauf; erkennbar an fehlendem review-kopf
-- und review-technik.
local function ist_review(blocks)
  for _, b in ipairs(blocks) do
    if b.t == "Div" and (b.classes:includes("review-kopf") or b.classes:includes("review-technik")) then
      return true
    end
  end
  return false
end

return {
  {
    Pandoc = function(doc)
      if not ist_review(doc.blocks) then return nil end
      n = 0
      doc.blocks = doc.blocks:walk(filter)
      return doc
    end,
  },
}
