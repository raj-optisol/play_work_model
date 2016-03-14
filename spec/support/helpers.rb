def json
  JSON.parse(response.body)
end

def create_uuid
  UUIDTools::UUID.random_create.to_s
end

def sign_in_user(user)
  account = Account.find_by_kyck_id(user.kyck_id)
  account ||= create_account(kyck_id: user.kyck_id)
  sign_in(account)
end

def stub_execute_action(klass, args=nil, return_value=nil, err=nil)
  action = Object.new
  if err
    puts "*raising"
    action.stub(:execute).with(args || any_args).and_raise(err)
  else
    action.stub(:execute).with(args || any_args).and_return(return_value)
  end
  klass.stub(:new) {action}
  action
end

def mock_execute_action(klass, args=nil, return_value=nil)
  action = Object.new
  action.should_receive(:execute).with(args || any_args).and_return(return_value)
  klass.stub(:new) {action}
  action
end

def should_not_execute_action(klass, args=nil, return_value=nil)
  action = Object.new
  action.should_not_receive(:execute).with(args || any_args)
  klass.stub(:new) {action}
  action
end

def mock_dont_execute_action(klass, args=nil)
  action = Object.new
  action.should_not_receive(:execute).with(args || any_args)
  klass.stub(:new) {action}
  action
end
