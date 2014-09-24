require_relative 'spec_helper'

describe Phone do
  before do
    def helpers
      @helpers ||= Phone.new.helpers
    end

    def create_recording(attrs = {})
      Recording.create({
        bus: 1,
        duration: 15,
        original_url: 'http://loopbeijing.com/recording.wav',
        web_url: 'http://loopbeijing.com/recording.mp3'
      }.merge(attrs))
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
    context 'leading zeros' do
      let(:digits) { '001' }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:confirm).with(digits.to_i)) }
    end
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
    before { create_recording(bus: line_with_recordings) }

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
    let!(:recording) { create_recording(bus: line) }
    before { get helpers.path_to(:first).with(line) }
    specify { expect(last_response).to be_redirect }
    specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, recording.id)) }
  end

  describe 'GET :play' do
    let(:line) { '123' }
    let!(:recording) { create_recording(bus: line) }
    before { get helpers.path_to(:play).with(line, recording.id) }
    specify { expect(last_response.status).to eq(200) }
    specify { expect(last_response.body).to include(recording.original_url) }
    specify { expect(last_response.body).to include(helpers.path_to(:next).with(line, recording.id)) }
  end

  describe 'GET :next' do
    let(:line) { '123' }
    let!(:newest_recording) { create_recording(bus: line) }
    let!(:middle_recording) { create_recording(created_at: 2.days.ago, bus: line) }
    let!(:oldest_recording) { create_recording(created_at: 3.days.ago, bus: line) }

    context 'with next recording' do
      before { get helpers.path_to(:next).with(line, newest_recording.id) }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, middle_recording.id)) }
    end

    context 'when next recording is hidden' do
      before { middle_recording.update(hidden: true) }
      before { get helpers.path_to(:next).with(line, newest_recording.id) }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:play).with(line, oldest_recording.id)) }
    end

    context 'with no next recording' do
      before { get helpers.path_to(:next).with(line, oldest_recording.id) }
      specify { expect(last_response).to be_redirect }
      specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:end).with(line)) }
    end
  end

  describe 'GET :prev' do
    let(:line) { '123' }
    let!(:newest_recording) { create_recording(bus: line) }
    let!(:middle_recording) { create_recording(created_at: 2.days.ago, bus: line) }
    let!(:oldest_recording) { create_recording(created_at: 3.days.ago, bus: line) }

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
        before { create_recording(bus: line) }
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
    let!(:recording) { create_recording(bus: line) }

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

  describe 'POST :create' do
    let(:line) { '123' }
    let(:url) { 'http://api.twilio.com/2010-04-01/Accounts/AC28dfa8542e02ffa84d6c6c4328268609/Recordings/RE49cc3599464c0ea759e4008e70c9ebb5' }
    let(:duration) { 3600 }
    let(:from) { '+16175551212' }
    before { ENV['NUMBER_SALT'] = 'test_salt' }
    before { post helpers.path_to(:create).with(line), 'RecordingUrl' => url, 'RecordingDuration' => duration, 'From' => from }
    specify { expect(Recording.last.bus).to eq(line.to_i) }
    specify { expect(Recording.last.original_url).to eq(url + '.wav') }
    specify { expect(Recording.last.web_url).to eq(url + '.mp3') }
    specify { expect(Recording.last.duration).to eq(duration) }
    specify { expect(Recording.last.number_hash).to eq(NumberSigner.sign(from)) }
    specify { expect(last_response).to be_redirect }
    specify { expect(last_response.location).to eq('http://' + last_request.host + helpers.path_to(:line).with(line)) }
  end
end
