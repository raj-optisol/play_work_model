module OrganizationRepository
  describe StaffRepository do
    let(:club) { create_club }
    let!(:staff) { add_user_to_org(user, club, title: 'Registrar') }
    let(:user) { regular_user }

    describe 'get staff by title and staffable' do
      it 'gets the staff' do
        result = described_class.get_staff_by_title_and_staffable(staff.title,
                                                                  club)
        result.map(&:kyck_id).should include(staff.kyck_id)
        assert result.first.is_a?(Staff)
      end

      it 'returns an empty list if title not supplied' do
        result = described_class.get_staff_by_title_and_staffable(nil,
                                                                  club)

        assert result.empty?
      end

      it 'returns an empty list if staffable not supplied' do
        result = described_class.get_staff_by_title_and_staffable(nil,
                                                                  club)

        assert result.empty?
      end
    end
  end
end
