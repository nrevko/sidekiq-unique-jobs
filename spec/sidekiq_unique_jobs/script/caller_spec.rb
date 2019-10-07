# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Script::Caller do
  subject { described_class }

  it { is_expected.to respond_to(:call_script).with(4).arguments }

  describe ".call_script" do
    subject(:call_script) { described_class.call_script(script_name, *script_arguments) }

    let(:jid)              { "abcefab" }
    let(:unique_key)       { "uniquejobs:abcefab" }
    let(:max_lock_time)    { 1 }
    let(:keys)             { [unique_key] }
    let(:argv)             { [jid, max_lock_time] }
    let(:script_arguments) { [keys, argv, redis] }
    let(:redis)            { Redis.new }
    let(:scriptsha)        { "abcdefab" }
    let(:script_name)      { :acquire_lock }
    let(:error_message)    { "Some interesting error" }

    before do
      allow(SidekiqUniqueJobs::Script).to receive(:call)
        .with(script_name, kind_of(Redis), keys: keys, argv: kind_of(Array))
    end

    shared_examples "script gets called with the correct arguments" do
      it "delegates to Script.call" do
        call_script
        expect(SidekiqUniqueJobs::Script).to have_received(:call)
          .with(script_name, kind_of(Redis), keys: keys, argv: a_collection_including(jid, max_lock_time))
      end
    end

    context "when arguments are a hash" do
      let(:script_arguments) { [redis, keys: keys, argv: argv] }

      context "without conn" do
        let(:redis) { nil }

        it_behaves_like "script gets called with the correct arguments"
      end

      context "with conn" do
        let(:redis) { Redis.new }

        it_behaves_like "script gets called with the correct arguments"
      end
    end

    context "when arguments are not a hash" do
      let(:script_arguments) { [keys, argv, redis] }

      context "without conn" do
        let(:redis) { nil }

        it_behaves_like "script gets called with the correct arguments"
      end

      context "with conn" do
        let(:redis) { Redis.new }

        it_behaves_like "script gets called with the correct arguments"
      end
    end
  end
end