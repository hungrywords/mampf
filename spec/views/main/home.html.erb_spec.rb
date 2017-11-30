require 'rails_helper'

RSpec.describe "main/home.html.erb", type: :view do
  it 'renders correctly' do
    user = FactoryBot.create(:user)
    allow(view).to receive(:user_signed_in?).and_return(user)
    render
    expect(rendered).to match('Herzlich willkommen')
  end
end
