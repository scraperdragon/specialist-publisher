class CmaCaseAttachmentsController < AbstractAttachmentsController

private
  def view_adapter(document)
    CmaCaseViewAdapter.new(document)
  end

  def document_id
    params.fetch("cma_case_id")
  end

  def services
    CmaCaseAttachmentServiceRegistry.new
  end

  def edit_path(document)
    edit_cma_case_path(document)
  end
end
