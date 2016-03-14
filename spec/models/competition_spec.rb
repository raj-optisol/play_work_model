require 'spec_helper'

describe Competition do
  subject {
    comp = create_competition(name: 'New Team', start_date: 1.day.from_now, end_date: 6.months.from_now)
    CompetitionRepository.persist comp
  }


  it "has a start date" do
    subject.start_date.should_not be_nil
  end

  it "has a staff" do
    subject.staff.should == []
  end

  it "has a kind that defaults to league" do
    subject.kind.should == :league
  end

  describe "#add_staff" do
    let(:user) {regular_user}

    it "adds the staff" do
      expect {
        s = subject.add_staff(user, {title: "Coach", permission_sets:[PermissionSet::MANAGE_TEAM]})
        OrganizationRepository::StaffRepository.persist(s)
      }.to change{subject.staff.count}.by(1)
    end
  end

  describe "#remove_staff" do
    before(:each) do
      @user = regular_user
      subject.add_staff(@user, title: 'Coach')
      UserRepository.persist @user
      @user._data.reload
      subject._data.reload

    end

    it "should remove the relatioship" do
      assert_difference lambda {subject.staff.count}, -1 do
        subject.remove_staff(@user)
        subject._data.reload
        CompetitionRepository.persist subject
      end
    end
  end

  describe "#create_division" do
    let(:user) {regular_user}

    it "adds the staff" do
      expect {
        subject.create_division({name: "Div 1", age:'15', gender:'m', kind:'blah'})
      }.to change{subject.divisions.count}.by(1)
    end
  end

  describe '#available_permission_sets' do
    let(:permissions) { subject.available_permission_sets }

    context 'when the competition is NOT sanctioned' do
      it 'should not return the MANAGE_CARDS permission' do
        subject.stub(:can_process_cards_for_sb?) { false }
        expect(permissions).not_to include('ManageCards')
      end
    end

    context 'when the competition is sanctioned' do
      context 'when the competition can process cards' do
        it 'should return the MANAGE_CARDS permission' do
          subject.stub(:can_process_cards_for_sb?) { true }
          expect(permissions).to include('ManageCards')
        end
      end

      context 'when the competition cannot process cards' do
        it 'should not return the MANAGE_CARDS permission' do
          subject.stub(:can_process_cards_for_sb?) { false }
          expect(permissions).not_to include('ManageCards')
        end
      end
    end
  end

end
