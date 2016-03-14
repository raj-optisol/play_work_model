#
# Objects you pass in are expected to return a compliant object from a
# call to to_model. It is perfectly fine for to_model to return self.
shared_examples "ActiveModel" do

  # == Responds to <tt>to_key</tt>
  #
  # Returns an Enumerable of all (primary) key attributes
  # or nil if model.persisted? is false
  describe "to_key" do
    it "handles to_key" do
      model.should respond_to(:to_key), "The model should respond to to_key"
      def model.persisted?() false end
      model.to_key.nil?.should be_true, "to_key should return nil when `persisted?` returns false"
    end
  end
  describe "to_param" do

    it "is handled" do
      subject.should respond_to(:to_param), "The model should respond to to_param"
      def subject.to_key() [1] end
      def subject.persisted?() false end
      subject.to_param.nil?.should be_true, "to_param should return nil when `persisted?` returns false"
    end
  end

  # == Responds to <tt>to_partial_path</tt>
  #
  # Returns a string giving a relative path.  This is used for looking up
  # partials. For example, a BlogPost model might return "blog_posts/blog_post"
  #
  describe "to_partial_path" do
    it "is handled" do
      subject.should respond_to(:to_partial_path), "The model should respond to to_partial_path"
      subject.to_partial_path.should be_a  String
    end
  end

  # == Responds to <tt>valid?</tt>
  #
  # Returns a boolean that specifies whether the object is in a valid or invalid
  # state.
  describe "valid?" do
    it "is handled" do
      subject.should respond_to(:valid?), "The model should respond to valid?"
      [true, false].should include(model.valid?), "valid?"
    end
  end

  # == Responds to <tt>persisted?</tt>
  #
  # Returns a boolean that specifies whether the object has been persisted yet.
  # This is used when calculating the URL for an object. If the object is
  # not persisted, a form for that object, for instance, will be POSTed to the
  # collection. If it is persisted, a form for the object will be PUT to the
  # URL for the object.

  describe "persisted" do
    it "is handled" do
      subject.should respond_to(:persisted?), "The model should respond to persisted?"
      [true, false].should include( model.persisted?), "persisted?"
    end
  end

  # == Naming
  #
  # Model.model_name must return a string with some convenience methods:
  # :human, :singular, and :plural. Check ActiveModel::Naming for more information.
  #
  describe "model_naming" do
    it "is handled" do

      subject.class.should respond_to(:model_name), "The model should respond to model_name"
      model_name = model.class.model_name
      model_name.should be_kind_of String
      model_name.human.should be_kind_of String
      model_name.singular.should be_kind_of String
      model_name.plural.should be_kind_of String
    end
  end

  # == Errors Testing
  #
  # Returns an object that has :[] and :full_messages defined on it. See below
  # for more details.
  #
  # Returns an Array of Strings that are the errors for the attribute in
  # question. If localization is used, the Strings should be localized
  # for the current locale. If no error is present, this method should
  # return an empty Array.
  describe "errors_aref" do
    it "is handled" do
      subject.should respond_to(:errors), "The model should respond to errors"
      subject.errors[:hello].should be_a(Array), "errors#[] should return an Array"
    end
  end

  # Returns an Array of all error messages for the object. Each message
  # should contain information about the field, if applicable.
  describe "errors_full_messages" do
    it "is handled" do
    subject.should respond_to(:errors), "The model should respond to errors"
    subject.errors.full_messages.should be_a(Array), "errors#full_messages should return an Array"
      
    end
  end

  private
  def model
    assert subject.respond_to?(:to_model), "The object should respond_to to_model"
    subject.to_model
  end

  def assert_boolean(result, name)
    assert result == true || result == false, "#{name} should be a boolean"
  end
end

