class ManualRepository
  def initialize(dependencies = {})
    @collection = dependencies.fetch(:collection)
    @factory = dependencies.fetch(:factory)
    @association_marshallers = dependencies.fetch(:association_marshallers, [])
  end

  def store(manual)
    manual_record = collection.find_or_initialize_by(manual_id: manual.id)
    manual_record.organisation_slug = manual.organisation_slug
    edition = manual_record.new_or_existing_draft_edition
    edition.attributes = attributes_for(manual)

    association_marshallers.each do |marshaller|
      marshaller.dump(manual, edition)
    end

    manual_record.save!
  end

  def fetch(manual_id)
    manual_record = collection.find_by(manual_id: manual_id)

    build_manual_for(manual_record)
  end

  def all
    collection.all_by_updated_at.lazy.map { |manual_record|
      build_manual_for(manual_record)
    }
  end

private
  attr_reader :collection, :factory, :association_marshallers

  def attributes_for(manual)
    {
      title: manual.title,
      summary: manual.summary,
    }
  end

  def build_manual_for(manual_record)
    edition = manual_record.latest_edition

    base_manual = factory.call(
      id: manual_record.manual_id,
      title: edition.title,
      summary: edition.summary,
      organisation_slug: manual_record.organisation_slug,
      updated_at: edition.updated_at,
    )

    association_marshallers.reduce(base_manual) { |manual, marshaller|
      marshaller.load(manual, edition)
    }
  end
end
