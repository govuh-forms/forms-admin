require "rails_helper"

RSpec.describe Forms::WelshTranslationUploadInput do
  let(:form) { create(:form) }

  describe "validations" do
    it "is invalid without a file" do
      input = described_class.new(form: form, file: nil)
      expect(input).to be_invalid
      expect(input.errors.full_messages_for(:file)).to include("File Select a file")
    end

    it "is invalid with an unsupported file type" do
      file = fixture_file_upload("invalid.txt", "text/plain")
      input = described_class.new(form: form, file: file)
      expect(input).to be_invalid
      expect(input.errors.full_messages_for(:file)).to include("File The selected file must be a CSV")
    end

    it "is invalid with a file that exceeds the maximum size" do
      file = fixture_file_upload("valid.csv", "text/csv")
      allow(file).to receive(:size).and_return((Forms::WelshTranslationUploadInput::MAX_SIZE_IN_MB + 1).megabytes)

      input = described_class.new(form: form, file: file)
      expect(input).to be_invalid
      expect(input.errors.full_messages_for(:file)).to include("File The selected file must be smaller than 10MB")
    end

    it "is valid with a supported file type" do
      Tempfile.create do |file|
        file.write("header1,header2\nvalue1,value2")
        file.rewind

        input = described_class.new(form: form, file: Rack::Test::UploadedFile.new(file, "text/csv"))
        expect(input).to be_valid
      end
    end
  end

  describe "#read_file" do
    let(:mock_welsh_csv_import_service) { instance_double(WelshCsvImportService) }
    let(:file) do
      Tempfile.create do |file|
        file.write("header1,header2\nvalue1,value2")
        file.rewind
        Rack::Test::UploadedFile.new(file, "text/csv")
      end
    end

    before do
      allow(WelshCsvImportService).to receive(:new).and_return(mock_welsh_csv_import_service)
    end

    after do
      file.unlink
    end

    it "returns false when the input is invalid" do
      input = described_class.new(form: form, file: nil)
      expect(input.read_file).to be false
    end

    context "when the CSV is valid" do
      let(:translations) { { "key1" => "translation1", "key2" => "translation2" } }

      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_return(translations)
      end

      it "returns the translations from the CSV" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to eq(translations)
      end
    end

    context "when the CSV is malformed" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(CSV::MalformedCSVError.new("error", 1))
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors.full_messages_for(:file)).to include("File The CSV is not formatted correctly. Download a new version of the CSV, then make your changes and upload it.")
      end
    end

    context "when the CSV is not UTF-8 encoded" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::InvalidEncodingError)
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors.full_messages_for(:file)).to include("File The selected file must be in CSV UTF-8 format. In Excel, select ‘File’, then ‘Save as’, then select ‘CSV UTF-8’ as the file type.")
      end
    end

    context "when the CSV has invalid headers" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::InvalidHeadersError)
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors.full_messages_for(:file)).to include("File The column headings in the CSV have been changed. Download a new version of the CSV, then make your changes and upload it.")
      end
    end

    context "when a DifferentNumberOfSelectionOptionsError is raised" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::DifferentNumberOfSelectionOptionsError.new("An error", 2))
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors.full_messages_for(:file)).to include("File The number of options for question 2 in the CSV does not match your form. Download a new version of the CSV, then make your changes and upload it.")
      end
    end

    context "when a SelectionOptionsMismatchError is raised" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::SelectionOptionsMismatchError.new("An error", 2))
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors.full_messages_for(:file)).to include("File The English options for question 2 in the CSV do not match your form. Download a new version of the CSV, then make your changes and upload it.")
      end
    end

    context "when a SelectionOptionTranslationsMissingError is raised" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::SelectionOptionTranslationsMissingError.new("An error", 2))
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors.full_messages_for(:file)).to include("File Question 2 is missing Welsh translations for one or more options. Add the missing translations, then upload the CSV again.")
      end
    end

    context "when a FormContentNotFoundError is raised" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::FormContentNotFoundError.new("An error", 2))
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors).to be_of_kind(:file, :form_content_not_found)
        expect(input.errors.full_messages_for(:file)).to include("File The form has changed since you downloaded the CSV. Download a new version of the CSV, then make your changes and upload it.")
        expect(input.error_row_number).to eq 2
      end
    end

    context "when a QuestionTextMismatchError is raised" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::QuestionTextMismatchError.new("An error", 2))
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors).to be_of_kind(:file, :question_text_mismatch)
        expect(input.errors.full_messages_for(:file)).to include("File The form has changed since you downloaded the CSV. Download a new version of the CSV, then make your changes and upload it.")
        expect(input.error_row_number).to eq 2
      end
    end

    context "when a ExitPageHeadingMismatchError is raised" do
      before do
        allow(mock_welsh_csv_import_service).to receive(:read).and_raise(WelshCsvImportService::ExitPageHeadingMismatchError.new("An error", 2))
      end

      it "returns false and adds an error" do
        input = described_class.new(form: form, file: file)
        expect(input.read_file).to be false
        expect(input.errors).to be_of_kind(:file, :exit_page_heading_mismatch)
        expect(input.errors.full_messages_for(:file)).to include("File The form has changed since you downloaded the CSV. Download a new version of the CSV, then make your changes and upload it.")
        expect(input.error_row_number).to eq 2
      end
    end
  end
end
