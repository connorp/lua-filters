--[[
html5-articles — create <article> tags for content rather than <section> tags

Copyright © 2021 Connor P. Jackson
License: MIT — see LICENSE file for details

concerns: 1. assumes the header is the first element in el.content
          2. doesn't check attributes for reserved characters,
]]

function make_section_divs (doc)
    -- run make_sections()
    return pandoc.Pandoc(pandoc.utils.make_sections(false, nil, doc.blocks),
                         doc.meta)
end

function construct_opening_tag(el, tag)
  -- when passed the tag type, construct it, with identifier, classes, attrs

  local open_tag = {'<', tag}

  -- add the identifier, if it exists
  if el.identifier ~= "" then
    table.insert(open_tag, string.format(' id="%s"', el.identifier))
  end

  -- remove the article and section classes from the Div
  local other_classes = {}
  for _, class in ipairs(el.classes) do
    if class ~= "article" and class ~= "section" then
      table.insert(other_classes, class)
    end
  end
  local class_string = table.concat(other_classes, " ")

  -- add the remaining classes to the open tag
  if class_string ~= "" then
    table.insert(open_tag, string.format(' class="%s"', class_string))
  end

  -- add the named attributes
  local article_attrs = {}
  for k, v in pairs(el.attributes) do
    table.insert(open_tag, string.format(' %s="%s"', k, v))
  end

  -- finish the opening tag, convert to string
  table.insert(open_tag, ">")
  return table.concat(open_tag, "")
end

function create_article_sections(el)
  -- Create the article tags, applying the attributes, and remove the Div
  if el.classes:includes('article') then
    local article_open_tag = construct_opening_tag(el, 'article')

    -- construct the list of elements to return
    local new_blocks = {pandoc.RawBlock('html', article_open_tag)}

    if el.content[1].tag == "Header" then
      -- if the first element of the div's content is a header, this div was
      -- created by --section-divs. Need to create the header tags manually so
      -- the later makeSections call doesn't add a new <section>
      -- NOTE: assume the header of interest is the first element of el.content.
      -- is this a bad assumption?

      local header_obj = el.content[1]
      -- remove the header object from the div's content
      table.remove(el.content, 1)
      local h_level_str = 'h' .. header_obj.level
      local header_open_tag = construct_opening_tag(header_obj, h_level_str)
      table.insert(new_blocks, pandoc.RawBlock('html', header_open_tag))

      -- the header's content (inside a Plain block since they are inlines)
      table.insert(new_blocks, pandoc.Plain(header_obj.content))

      local header_closing_tag = string.format('</%s>', h_level_str)
      table.insert(new_blocks, pandoc.RawBlock('html', header_closing_tag))
    end

    -- the div content
    for i, v in ipairs(el.content) do
      table.insert(new_blocks, v)
    end
    table.insert(new_blocks, pandoc.RawBlock('html', '</article>'))

    return new_blocks
  end
end

-- Only run for HTML5 output
if FORMAT:match 'html' and (not FORMAT:match '4') then
  return {
      -- Have to make the divs first, so force the order
      {Pandoc = make_section_divs},
      {Div = create_article_sections}
  }
end
