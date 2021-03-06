class AaibReportAttachmentsController < AbstractAttachmentsController

private
  def view_adapter(document)
    AaibReportViewAdapter.new(document)
  end

  def document_id
    params.fetch("aaib_report_id")
  end

  def services
    AaibReportAttachmentServiceRegistry.new
  end

  def edit_path(document)
    edit_aaib_report_path(document)
  end
end
