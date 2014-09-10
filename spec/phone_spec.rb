require_relative 'spec_helper'

describe Phone do
  before do
    def helpers
      @helpers ||= Phone.new.helpers
    end
  end

  describe 'GET :main' do
    before { get helpers.path_to(:main) }
    specify { expect(last_response.status).to eq(200) }
    specify { expect(last_response.body).to include('Welcome') }
  end

  describe 'POST :main' do
    let(:digits) { '123' }
    before { post helpers.path_to(:main), 'Digits' => digits }
    specify { expect(last_response).to be_redirect }
    specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:confirm).with(digits)) }
  end

  describe 'GET :confirm' do
    before { get helpers.path_to(:confirm).with('123') }
    specify { expect(last_response.status).to eq(200) }
  end

  describe 'POST :confirm' do
    let(:line) { '123' }
    before { post helpers.path_to(:confirm).with(line), 'Digits' => digits }

    context 'entered 0' do
      let(:digits) { '0' }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:main)) }
    end

    context 'entered not 0' do
      let(:digits) { '5' }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:line).with(line)) }
    end
  end

  describe 'GET :line' do
    let(:line_with_recordings) { '123' }
    before { Recording.create!(bus: line_with_recordings, url: 'http://loopbeijing.com/recording.wav') }

    context 'has recordings' do
      let(:line) { line_with_recordings }
      before { get helpers.path_to(:line).with(line) }
      specify { expect(last_response.status).to eq(200) }
      specify { expect(last_response.body).to include('Playing') }
      specify { expect(last_response.body).to include(helpers.path_to(:first).with(line)) }
    end

    context 'no recordings yet' do
      let(:line) { '456' }
      before { get helpers.path_to(:line).with(line) }
      specify { expect(last_response.status).to eq(200) }
      specify { expect(last_response.body).to include('no recordings') }
    end
  end

  describe 'GET :first' do
    let(:line) { '123' }
    let!(:recording) { Recording.create!(bus: line, url: 'http://loopbeijing.com/recording.wav') }
    before { get helpers.path_to(:first).with(line) }
    specify { expect(last_response).to be_redirect }
    specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, recording.id)) }
  end

  describe 'GET :play' do
    let(:line) { '123' }
    let!(:recording) { Recording.create!(bus: line, url: 'http://loopbeijing.com/recording.wav') }
    before { get helpers.path_to(:play).with(line, recording.id) }
    specify { expect(last_response.status).to eq(200) }
    specify { expect(last_response.body).to include(recording.url) }
    specify { expect(last_response.body).to include(helpers.path_to(:next).with(line, recording.id)) }
  end

  describe 'GET :next' do
    let(:line) { '123' }
    let!(:newest_recording) { Recording.create!(bus: line, url: 'http://loopbeijing.com/recording.wav') }
    let!(:middle_recording) { Recording.create!(created_at: 2.days.ago, bus: line, url: 'http://loopbeijing.com/recording.wav') }
    let!(:oldest_recording) { Recording.create!(created_at: 3.days.ago, bus: line, url: 'http://loopbeijing.com/recording.wav') }

    context 'with next recording' do
      before { get helpers.path_to(:next).with(line, newest_recording.id) }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, middle_recording.id)) }
    end

    context 'with no next recording' do
      before { get helpers.path_to(:next).with(line, oldest_recording.id) }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:end).with(line)) }
    end
  end

  describe 'GET :prev' do
    let(:line) { '123' }
    let!(:newest_recording) { Recording.create!(bus: line, url: 'http://loopbeijing.com/recording.wav') }
    let!(:middle_recording) { Recording.create!(created_at: 2.days.ago, bus: line, url: 'http://loopbeijing.com/recording.wav') }
    let!(:oldest_recording) { Recording.create!(created_at: 3.days.ago, bus: line, url: 'http://loopbeijing.com/recording.wav') }

    context 'with prev recording' do
      before { get helpers.path_to(:prev).with(line, oldest_recording.id) }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, middle_recording.id)) }
    end

    context 'with no prev recording' do
      before { get helpers.path_to(:prev).with(line, newest_recording.id) }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, newest_recording.id)) }
    end
  end

  describe 'GET :end' do
    let(:line) { '123' }
    before { get helpers.path_to(:end).with(line) }
    specify { expect(last_response.status).to eq(200) }
    specify { expect(last_response.body).to include('no more') }
    specify { expect(last_response.body).to include(helpers.path_to(:main)) }
  end

  describe 'POST :line' do
    let(:line) { '123' }

    context "entered #{Phone::HOME_BUTTON}" do
      let(:digits) { Phone::HOME_BUTTON }
      before { post helpers.path_to(:line).with(line), 'Digits' => digits }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:main)) }
    end

    context "entered #{Phone::RECORD_BUTTON}" do
      let(:digits) { Phone::RECORD_BUTTON }
      before { post helpers.path_to(:line).with(line), 'Digits' => digits }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:new).with(line)) }
    end

    context 'entered something else' do
      context 'has recordings' do
        let(:digits) { 'x' }
        before { Recording.create!(bus: line, url: 'http://loopbeijing.com/recording.wav') }
        before { post helpers.path_to(:line).with(line), 'Digits' => digits }
        specify { expect(last_response).to be_redirect }
        specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:first).with(line)) }
      end

      context 'does not have recordings' do
        let(:digits) { '5' }
        before { post helpers.path_to(:line).with(line), 'Digits' => digits }
        specify { expect(last_response).to be_redirect }
        specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:line).with(line)) }
      end
    end
  end

  describe 'POST :play' do
    let(:line) { '123' }
    let!(:recording) { Recording.create!(bus: line, url: 'http://loopbeijing.com/recording.wav') }

    context "entered #{Phone::HOME_BUTTON}" do
      let(:digits) { Phone::HOME_BUTTON }
      before { post helpers.path_to(:play).with(line, recording.id), 'Digits' => digits }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:main)) }
    end

    context "entered #{Phone::RECORD_BUTTON}" do
      let(:digits) { Phone::RECORD_BUTTON }
      before { post helpers.path_to(:play).with(line, recording.id), 'Digits' => digits }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:new).with(line)) }
    end

    context "entered #{Phone::NEXT_BUTTON}" do
      let(:digits) { Phone::NEXT_BUTTON }
      before { post helpers.path_to(:play).with(line, recording.id), 'Digits' => digits }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:next).with(line, recording.id)) }
    end

    context "entered #{Phone::PREV_BUTTON}" do
      let(:digits) { Phone::PREV_BUTTON }
      before { post helpers.path_to(:play).with(line, recording.id), 'Digits' => digits }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:prev).with(line, recording.id)) }
    end

    context 'entered something else' do
      let(:digits) { 'x' }
      before { post helpers.path_to(:play).with(line, recording.id), 'Digits' => digits }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, recording.id)) }
    end
  end

  describe 'GET :new' do
    let(:line) { '123' }
    before { get helpers.path_to(:new).with(line) }
    specify { expect(last_response.status).to eq(200) }
    specify { expect(last_response.body).to include('<Record') }
  end

  describe 'POST :play' do
    let(:line) { '123' }
    let(:url) { 'http://api.twilio.com/2010-04-01/Accounts/AC28dfa8542e02ffa84d6c6c4328268609/Recordings/RE49cc3599464c0ea759e4008e70c9ebb5' }
    before { post helpers.path_to(:create).with(line), 'RecordingUrl' => url }
    specify { expect(Recording.where(bus: line, url: url)).to exist }
    specify { expect(last_response).to be_redirect }
    specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:line).with(line)) }
  end
end
