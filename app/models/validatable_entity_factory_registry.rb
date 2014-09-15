require "validators/aaib_report_validator"
require "validators/change_note_validator"
require "validators/cma_case_validator"
require "validators/drug_safety_update_validator"
require "validators/international_development_fund_validator"
require "validators/manual_document_validator"
require "validators/manual_validator"
require "validators/medical_safety_alert_validator"
require "validators/null_validator"

# TODO: remove these dependencies
require "id_generator"
require "builders/manual_document_builder"
require "manual_with_documents"
require "slug_generator"
require "specialist_document"

class ValidatableEntityFactoryRegistry
  def initialize(entity_factory_registry)
    @entity_factory_registry = entity_factory_registry
  end

  def aaib_report_factory
    ->(*args) {
      AaibReportValidator.new(
        entity_factory_registry.aaib_report_factory.call(*args),
      )
    }
  end

  def cma_case_factory
    ->(*args) {
      CmaCaseValidator.new(
        entity_factory_registry.cma_case_factory.call(*args),
      )
    }
  end

  def drug_safety_update_factory
    ->(*args){
      DrugSafetyUpdateValidator.new(
        entity_factory_registry.drug_safety_update_factory.call(*args),
      )
    }
  end

  def medical_safety_alert_factory
    ->(*args){
      MedicalSafetyAlertValidator.new(
        entity_factory_registry.medical_safety_alert_factory.call(*args),
      )
    }
  end

  def international_development_fund_factory
    ->(*args){
      InternationalDevelopmentFundValidator.new(
        entity_factory_registry.international_development_fund_factory.call(*args),
      )
    }
  end

  def manual_with_documents
    ->(manual, attrs){
      ManualValidator.new(
        NullValidator.new(
          ManualWithDocuments.new(
            manual_document_builder,
            manual,
            attrs,
          )
        )
      )
    }
  end

  def manual_document_builder
    ManualDocumentBuilder.new(
      factory_factory: manual_document_factory_factory,
      id_generator: IdGenerator,
    )
  end


  def manual_document_factory_factory
    ->(manual) {
      ->(id, editions) {
        slug_generator = SlugGenerator.new(prefix: manual.slug)

        ChangeNoteValidator.new(
          ManualDocumentValidator.new(
            SpecialistDocument.new(
              slug_generator,
              entity_factory_registry.edition_factory,
              id,
              editions,
            ),
          )
        )
      }
    }
  end

private

  attr_reader :entity_factory_registry
end
