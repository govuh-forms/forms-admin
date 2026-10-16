require "rails_helper"

RSpec.describe "Native S3-only GOV.UH Forms receiving arrangements" do
  let(:group) { create(:group) }
  let(:form) { create(:form, :new_form, :with_group, group:) }
  let(:task_status) { TaskStatusService.new(form:) }

  before do
    form.delivery_configurations.create!(
      delivery_method: "s3", delivery_schedule: "immediate", formats: %w[json]
    )
    form.update!(
      s3_bucket_name: "uh-interior-citizenship-submissions",
      s3_bucket_region: "garage",
      s3_bucket_aws_account_id: nil,
      submission_email: nil
    )
  end

  it "accepts a properly configured S3-only receiving destination without requiring an email address" do
    expect(form.only_s3_delivery_enabled?).to be true
    expect(task_status.send(:submission_email_status)).to eq(:completed)
    expect(task_status.send(:confirm_submission_email_status)).to eq(:completed)
    expect(task_status.all_incomplete_tasks).not_to include(:missing_submission_email)
  end

  it "does not consider missing bucket/region details an accepted receiving destination" do
    form.update!(s3_bucket_name: nil)
    expect(task_status.send(:submission_email_status)).to eq(:not_started)
    expect(task_status.all_incomplete_tasks).to include(:missing_submission_email)
  end

  it "does not permit unsupported file-upload questions without a secured evidence route" do
    allow(form).to receive(:file_upload_question_count).and_return(1)
    expect(task_status.send(:submission_email_status)).to eq(:not_started)
  end

  it "still requires publication, privacy and contact review" do
    expect(task_status.all_incomplete_tasks).to include(:missing_privacy_policy_url, :missing_contact_details)
    expect(task_status.mandatory_tasks_completed?).to be false
  end
end
