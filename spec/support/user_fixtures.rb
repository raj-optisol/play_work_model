def valid_user_params
  {
    email: 'fred@flintstone.com',
    first_name: 'Fred',
    last_name: 'Flintstone',
    birthdate:(DateTime.now-15.years).to_date.to_s
  }
end

