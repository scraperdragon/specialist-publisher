module RerenderingHelpers
  def destroy_all_rendered_specialist_document_records
    RenderedSpecialistDocument.destroy_all
  end

  def check_all_published_documents_have_valid_rendered_specialist_documents
    published_slugs = cma_case_repository.all.select(&:published?).map(&:slug).sort
    rendered_slugs = RenderedSpecialistDocument.all.map(&:slug).sort

    expect(published_slugs).to eq(rendered_slugs)
  end
end
