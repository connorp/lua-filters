function make_section_divs (doc)
    -- run make_sections()
    return pandoc.Pandoc(pandoc.utils.make_sections(false, nil, doc.blocks),
                         doc.meta)
end

-- expand functionality to any block-level tag not currently handled by pandoc:
-- candidates: address, article, aside, canvas, dd, dl, dt, fieldset, form,
--             noscript, tfoot, video

function create_article_sections(el)
  -- Create the article tags, applying the attributes, and remove the Div
  -- applied to Divs of class "article"

  if el.classes:includes('article') then
    -- build up the string for the opening tag
    local opentag = {'<article'}

    -- add the identifier, if it exists
    if el.identifier ~= "" then
      table.insert(opentag, string.format(' id="%s"', el.identifier))
    end

    -- remove the article and section classes from the Div
    local otherclasses = {}
    for i, class in ipairs(el.classes) do
      if class ~= "article" and class ~= "section" then
        table.insert(otherclasses, class)
      end
    end
    local class_string = table.concat(otherclasses, " ")

    -- add the remaining classes to the open tag
    if class_string ~= "" then
      table.insert(opentag, string.format(' class="%s"', class_string))
    end

    -- add the named attributes
    local article_attrs = {}
    for k, v in pairs(el.attributes) do
      table.insert(opentag, string.format(' %s="%s"', k, v))
    end

    -- finish the opening tag, convert to string
    table.insert(opentag, ">")
    opentag_str = table.concat(opentag, "")

    -- remove the article and section classes from the header, looping from the
    -- end of the table to avoid indexing problems when removing elements.
    -- NOTE: assume the header of interest is the first element of el.content
    -- is this a bad assumption?
    for i = #(el.content[1].classes), 1, -1 do
      class = el.content[1].classes[i]
      if class ~= "article" and class ~= "section" then
        table.remove(el.content[1].classes, i)
      end
    end

    local new_blocks = {pandoc.RawBlock('html', opentag_str)}
    for i, v in ipairs(el.content) do
      table.insert(new_blocks, v)
    end
    table.insert(new_blocks, pandoc.RawBlock('html', '</article>'))
    return new_blocks
  end
end

--if FORMAT:match 'html' then
return {
    -- Have to make the divs first, so force the order
    {Pandoc = make_section_divs},
    {Div = create_article_sections}
}
--end
