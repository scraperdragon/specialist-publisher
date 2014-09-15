class RepositoryRegistry
  def initialize(entity_factories:)
    @entity_factories = entity_factories
  end

  def aaib_report_repository
    SpecialistDocumentRepository.new(
      specialist_document_editions: SpecialistDocumentEdition.where(document_type: "aaib_report"),
      document_factory: entity_factories.aaib_report_factory,
    )
  end

  def cma_case_repository
    SpecialistDocumentRepository.new(
      specialist_document_editions: SpecialistDocumentEdition.where(document_type: "cma_case"),
      document_factory: entity_factories.cma_case_factory,
    )
  end

  def drug_safety_update_repository
    SpecialistDocumentRepository.new(
      specialist_document_editions: SpecialistDocumentEdition.where(document_type: "drug_safety_update"),
      document_factory: get(:validatable_drug_safety_update_factory),
    )
  end

  def medical_safety_alert_repository
    SpecialistDocumentRepository.new(
      specialist_document_editions: SpecialistDocumentEdition.where(document_type: "medical_safety_alert"),
      document_factory: get(:validatable_medical_safety_alert_factory),
    )
  end

  def international_development_fund_repository
    SpecialistDocumentRepository.new(
      specialist_document_editions: SpecialistDocumentEdition.where(document_type: "international_development_fund"),
      document_factory: get(:validatable_international_development_fund_factory),
    )
  end

private

  attr_reader :entity_factories

  def scoped_editions(document_type)
  end
end

class EntityFactoryRegistry
  def aaib_report_factory
    ->(*args) {
      AaibReport.new(
        SpecialistDocument.new(
          SlugGenerator.new(prefix: "aaib-reports"),
          edition_factory,
          *args,
        )
      )
    }
  end

  def cma_case_factory
    ->(*args){
      CmaCase.new(
        SpecialistDocument.new(
          SlugGenerator.new(prefix: "cma-cases"),
          edition_factory,
          *args,
        ),
      )
    }
  end

private

  def edition_factory
    SpecialistDocumentEdition.method(:new)
  end
end

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

private


  attr_reader :entity_factory_registry
  attr_reader :entity_factory_registry
end
