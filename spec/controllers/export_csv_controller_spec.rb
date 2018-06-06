require "rails_helper"

describe ExportCsvController do
  let(:export_filename) { "user-archive-codinghorror-150115-234817-999.csv.gz" }

  context "while logged in as normal user" do
    before { @user = log_in(:user) }

    describe ".export_entity" do
      it "enqueues export job" do
        Jobs.expects(:enqueue).with(:export_csv_file, has_entries(entity: "user_archive", user_id: @user.id))
        post :export_entity, params: { entity: "user_archive" }, format: :json
        expect(response).to be_success
      end

      it "should not enqueue export job if rate limit is reached" do
        Jobs::ExportCsvFile.any_instance.expects(:execute).never
        UserExport.create(file_name: "user-archive-codinghorror-150116-003249", user_id: @user.id)
        post :export_entity, params: { entity: "user_archive" }, format: :json
        expect(response).not_to be_success
      end

      it "returns 404 when normal user tries to export admin entity" do
        post :export_entity, params: { entity: "staff_action" }, format: :json
        expect(response).not_to be_success
      end
    end
  end

  context "while logged in as an admin" do
    before { @admin = log_in(:admin) }

    describe ".export_entity" do
      it "enqueues export job" do
        Jobs.expects(:enqueue).with(:export_csv_file, has_entries(entity: "staff_action", user_id: @admin.id))
        post :export_entity, params: { entity: "staff_action" }, format: :json
        expect(response).to be_success
      end

      it "should not rate limit export for staff" do
        Jobs.expects(:enqueue).with(:export_csv_file, has_entries(entity: "staff_action", user_id: @admin.id))
        UserExport.create(file_name: "screened-email-150116-010145", user_id: @admin.id)
        post :export_entity, params: { entity: "staff_action" }, format: :json
        expect(response).to be_success
      end
    end
  end
end