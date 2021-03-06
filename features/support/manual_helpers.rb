require "gds_api/test_helpers/publishing_api"

module ManualHelpers
  include GdsApi::TestHelpers::PublishingApi

  def create_manual(fields, save: true)
    visit new_manual_path
    fill_in_fields(fields)

    save_as_draft if save
  end

  def create_manual_document(manual_title, fields)
    go_to_manual_page(manual_title)
    click_on "Add section"

    fill_in_fields(fields)

    save_as_draft
  end

  def edit_manual(manual_title, new_fields)
    go_to_edit_page_for_manual(manual_title)
    fill_in_fields(new_fields)

    save_as_draft
  end

  def edit_manual_document(manual_title, section_title, new_fields)
    go_to_manual_page(manual_title)
    click_on section_title
    click_on "Edit"
    fill_in_fields(new_fields)

    save_as_draft
  end

  def save_as_draft
    click_on "Save as draft"
  end

  def publish_manual
    click_on "Publish"
  end

  def check_manual_exists_with(attributes)
    go_to_manual_page(attributes.fetch(:title))
    expect(page).to have_content(attributes.fetch(:summary))
  end

  def check_manual_document_exists_with(manual_title, attributes)
    go_to_manual_page(manual_title)
    click_on(attributes.fetch(:section_title))

    attributes.values.each do |attr_val|
      expect(page).to have_content(attr_val)
    end
  end

  def go_to_edit_page_for_manual(manual_title)
    go_to_manual_page(manual_title)
    click_on("Edit manual")
  end

  def check_for_errors_for_fields(field)
    expect(page).to have_content("#{field.titlecase} can't be blank")
  end

  def go_to_manual_page(manual_title)
    visit manuals_path
    click_link manual_title
  end

  def check_manual_was_published_to_panopticon(slug, attrs)
    expect(fake_panopticon).to have_received(:create_artefact!)
      .with(
        hash_including(
          name: attrs.fetch(:title),
          slug: slug,
          state: "live",
          kind: "manual",
          rendering_app: "manuals-frontend",
        )
      ).at_least(:once)
  end

  def check_manual_and_documents_were_published(manual_slug, manual_attrs, document_slug, document_attrs)
    check_manual_was_published_to_panopticon(manual_slug, manual_attrs)

    check_manual_is_published_to_publishing_api(manual_slug, manual_attrs)
    check_manual_document_is_published_to_publishing_api(document_slug, document_attrs)

    check_manual_is_published_to_rummager(manual_slug, manual_attrs)
    check_manual_section_is_published_to_rummager(document_slug, document_attrs, manual_attrs)
  end

  def check_manual_is_published_to_rummager(slug, attrs)
    expect(fake_rummager).to have_received(:add_document)
      .with(
        "manual",
        slug,
        hash_including(
          title: attrs.fetch(:title),
          link: slug,
          indexable_content: attrs.fetch(:summary),
        )
      ).at_least(:once)
  end

  def check_manual_is_published_to_publishing_api(slug, attrs)
    assert_publishing_api_put_item("/#{slug}",
      "base_path" => "/#{slug}",
      "format" => "manual",
      "rendering_app" => "manuals-frontend",
      "publishing_app" => "specialist-publisher",
    )
  end

  def check_manual_document_is_published_to_publishing_api(slug, attrs)
    assert_publishing_api_put_item("/#{slug}",
      "base_path" => "/#{slug}",
      "format" => "manual-section",
      "rendering_app" => "manuals-frontend",
      "publishing_app" => "specialist-publisher",
    )
  end

  def check_manual_section_is_published_to_rummager(slug, attrs, manual_attrs)
    expect(fake_rummager).to have_received(:add_document)
      .with(
        "manual_section",
        slug,
        hash_including(
          title: "#{manual_attrs.fetch(:title)}: #{attrs.fetch(:title)}",
          link: slug,
          indexable_content: attrs.fetch(:body),
        )
      ).at_least(:once)
  end

  def create_manual_document_for_preview(manual_title, fields)
    go_to_manual_page(manual_title)
    click_on "Add section"
    fill_in_fields(fields)
  end

  def check_for_document_body_preview(text)
    within(".preview") do
      expect(page).to have_css("p", text: text)
    end
  end

  def copy_embed_code_for_attachment_and_paste_into_manual_document_body(title)
    snippet = within(".attachments") do
      page
        .find("li", text: /#{title}/)
        .find("span.snippet")
        .text
    end

    body_text = find("#document_body").value
    fill_in("Section body", with: body_text + snippet)
  end

  def change_note_slug(manual_slug)
    change_note_slug = [manual_slug, "updates"].join("/")
  end

  def check_manual_change_note_exported(manual_slug, expected_note)
    slug = change_note_slug(manual_slug)

    exported_history = ManualChangeHistory
      .find_by_slug(slug)

    most_recent_section_update = exported_history.updates.last

    expect(most_recent_section_update.fetch("change_note"))
      .to eq(@change_note)
  end

  def check_change_note_value(manual_title, document_title, expected_value)
    go_to_manual_page(manual_title)
    click_on document_title
    click_on "Edit section"

    change_note_field_value = page.find("textarea[name='document[change_note]']").text
    expect(change_note_field_value).to eq(expected_value)
  end

  def check_manual_can_be_created
    @manual_fields = {
      title: "Example Manual Title",
      summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    }

    create_manual(@manual_fields)
    check_manual_exists_with(@manual_fields)
  end

  def check_manual_cannot_be_published
    document_fields = {
      section_title: "Section 1",
      section_summary: "Section 1 summary",
      section_body: "Section 1 body",
    }
    create_manual_document(@manual_fields.fetch(:title), document_fields)

    go_to_manual_page(@manual_fields.fetch(:title))
    expect(page).not_to have_button("Publish")
  end

  def check_manual_cannot_be_withdrawn
    go_to_manual_page(@manual_fields.fetch(:title))
    expect(page).not_to have_button("Withdraw")
  end

  def change_manual_without_saving(title, fields)
    go_to_edit_page_for_manual(title)
    fill_in_fields(fields)
  end

  def check_for_manual_body_preview
    expect(current_path).to match(%r{/manuals/([0-9a-f-]+|new)})
    within(".preview") do
      expect(page).to have_css("p", text: "Body for preview")
    end
  end
end
