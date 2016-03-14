module KyckRegistrar
  module Import
    describe RowValidator do
      subject {described_class.new}

      describe "#validate" do
        context "when kind is not spedified" do
          it "returns an error" do
            subject.validate({})
            subject.errors.first.should =~ /'kind' not specified/
          end
        end
      end

      describe "#validate_player_row" do
        context "for a valid row" do
          let(:valid_player) {
            {
              first_name: 'Bob',
              last_name:  'Barker',
              parent_email:      'bob@pir.com',
              position:   'Keeper',
              kind:       'player',
              gender:     'male',
              birthdate:  '2001/01/04',
              phone_number: '777-333-3333',
              jersey_number: '34'

            }
          }

          it "returns true" do
            subject.validate(valid_player).should be_true
          end
        end

        context "for an invalid player" do
          let(:invalid_player) {
            {
              position:   'Keeper',
              kind:       'player',
              gender:     'male',
              birthdate:  '2001/01/04',
              phone_number: '777-333-3333',
              jersey_number: '34'

            }
          }

          it "returns an array of errors" do
            subject.validate(invalid_player)
            subject.errors.should be_a Array
          end

          context "with no birthdate" do
            before do
              invalid_player.delete(:birthdate)
            end

            it "returns an error for birthdate" do
              subject.validate(invalid_player)
              subject.errors.select {|e| e['birthdate']}.should_not be_empty
            end

          end
        end
      end

      describe "#validate_staff_row" do
        context "for a valid row" do
          let(:valid_staff) {
            {
              first_name:   'Bob',
              last_name:    'Barker',
              email:        'bob@pir.com',
              title:        'Admin',
              kind:         'staff',
              phone_number: '777-333-3333',
              persmissions: 'MANAGE_PLAYER'
            }
          }

          it "returns true" do
            subject.validate(valid_staff).should be_true
          end
        end

        context "for an invalid staff" do
          let(:invalid_staff) {
            {
              title:   'Keeper',
              kind:    'staff'
            }
          }

          it "returns an array of errors" do
            subject.validate(invalid_staff)
            subject.errors.should_not be_empty
          end

          it "returns false" do
            subject.validate(invalid_staff).should be_false
          end
        end
      end
    end
  end
end
