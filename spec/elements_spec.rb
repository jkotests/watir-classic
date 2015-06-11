# encoding: utf-8
require File.expand_path("watirspec/spec_helper", File.dirname(__FILE__))

describe "Elements" do

  before :each do
    browser.goto(WatirSpec.url_for("non_control_elements.html"))
  end

  it "returns a collection of Watir::Element when searching with :css" do
    elements = browser.elements(:css => "div")
    expect(elements.size).to be > 0
    elements.each do |element|
      expect(element.class).to eq(Watir::Element)
    end
  end

end
