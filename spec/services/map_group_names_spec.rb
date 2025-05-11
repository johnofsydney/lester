require 'rails_helper'
require 'spec_helper'

RSpec.describe MapGroupNames, type: :service do
  describe '#call' do
    it 'returns "Get Up Limited" for names containing "GetUp" or "Get Up"' do
      expect(described_class.new('GetUp Foo').call).to eq('Get Up Limited')
      expect(described_class.new('Get Up Limited').call).to eq('Get Up Limited')
    end

    it 'returns "Australian Hotels Association" for names containing "Australian Hotels Association"' do
      expect(described_class.new('Australian Hotels Association').call).to eq('Australian Hotels Association')
    end

    it 'returns "Advance Australia" for names containing "Advance Aus" or similar' do
      expect(described_class.new('Advance Aus').call).to eq('Advance Australia')
      expect(described_class.new('Advanced Aus').call).to eq('Advance Australia')
      expect(described_class.new('Advance').call).to eq('Advance Australia')
    end

    it 'returns "It\'s Not a Race Limited" for names containing "Not A Race"' do
      expect(described_class.new('Not A Race').call).to eq("It's Not a Race Limited")
    end

    it 'returns "Australian Council of Trade Unions" for names containing "ACTU"' do
      expect(described_class.new('ACTU').call).to eq('Australian Council of Trade Unions')
    end

    it 'returns "Climate 200 Pty Ltd" for names containing "Climate 200"' do
      expect(described_class.new('Climate 200').call).to eq('Climate 200 Pty Ltd')
      expect(described_class.new('Climate200').call).to eq('Climate 200 Pty Ltd')
    end

    it 'returns "Australian Chamber of Commerce and Industry" for names containing variations of "Australian Chamber of Commerce and Industry"' do
      expect(described_class.new('Australian Chamber of Commerce and Industry').call).to eq('Australian Chamber of Commerce and Industry')
      expect(described_class.new('Australia Chamber of Commerce and Industry').call).to eq('Australian Chamber of Commerce and Industry')
    end

    it 'returns "Hadley Holdings Pty Ltd" for names containing "Hadley Holdings"' do
      expect(described_class.new('Hadley Holdings').call).to eq('Hadley Holdings Pty Ltd')
    end

    it 'returns "University of NSW" for names containing "University of NSW" or similar' do
      expect(described_class.new('University of NSW').call).to eq('University of NSW')
      expect(described_class.new('UNSW').call).to eq('University of NSW')
    end

    it 'returns "Australian Communities Foundation Limited" for names containing "Australian Communities Foundation"' do
      expect(described_class.new('Australian Communities Foundation').call).to eq('Australian Communities Foundation Limited')
    end

    it 'returns "Australians for Unity Ltd" for names containing "Australians for Unity"' do
      expect(described_class.new('Australians for Unity').call).to eq('Australians for Unity Ltd')
      expect(described_class.new('Australian for Unity').call).to eq('Australians for Unity Ltd')
      expect(described_class.new('Australia for Unity').call).to eq('Australians for Unity Ltd')
      expect(described_class.new('AFUL').call).to eq('Australians for Unity Ltd')
    end

    it 'returns "Australians for Indigenous Constitutional Recognition" for names containing variations of "Australians for Indigenous Constitutional Recognition"' do
      expect(described_class.new('Australians for Indigenous Constitutional Recognition').call).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new('Australians for Indigenous Constitution Recognition').call).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new('Australians for Indigenous Constitution Recongition').call).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new('AICR').call).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new('aicr').call).to eq('Australians for Indigenous Constitutional Recognition')
    end

    it 'returns "Climate Action Network Australia" for names containing "Climate Action Network Australia"' do
      expect(described_class.new('Climate Action Network Australia').call).to eq('Climate Action Network Australia')
    end

    it 'returns "Stand UP: Jewish Commitment TO A Better World" for names containing "Stand UP: Jewish Commitment TO A Better World"' do
      expect(described_class.new('Stand UP: Jewish Commitment TO A Better World').call).to eq('Stand UP: Jewish Commitment TO A Better World')
    end

    it 'returns "The Australia Institute" for names containing "Australia Institute"' do
      expect(described_class.new('Australia Institute').call).to eq('The Australia Institute')
      expect(described_class.new('The Australia Institute').call).to eq('The Australia Institute')
    end

    it 'returns "The Dugdale Trust for Women and Girls" for names containing "The Dugdale Trust for Women and Girls"' do
      expect(described_class.new('The Dugdale Trust for Women and Girls').call).to eq('The Dugdale Trust for Women and Girls')
    end

    it 'returns "Uphold and Recognise Limited" for names containing "Uphold and Recognise"' do
      expect(described_class.new('Uphold and Recognise').call).to eq('Uphold and Recognise Limited')
    end

    it 'returns "Keldoulis Investments Pty Ltd" for names containing "Keldoulis Investments"' do
      expect(described_class.new('Keldoulis Investments').call).to eq('Keldoulis Investments Pty Ltd')
    end

    it 'returns "Turner Components Pty Ltd" for names containing "Turner Components"' do
      expect(described_class.new('Turner Components').call).to eq('Turner Components Pty Ltd')
    end

    it 'returns "Glencore Australia" for names containing "Glencore Australia"' do
      expect(described_class.new('Glencore Australia').call).to eq('Glencore Australia')
    end

    it 'returns "Whitehaven Coal Limited" for names containing "Whitehaven Coal"' do
      expect(described_class.new('Whitehaven Coal').call).to eq('Whitehaven Coal Limited')
    end

    it 'returns "Woodside Energy" for names containing "Woodside Energy"' do
      expect(described_class.new('Woodside Energy').call).to eq('Woodside Energy')
    end

    it 'returns "Origin Energy" for names containing "Origin Energy"' do
      expect(described_class.new('Origin Energy').call).to eq('Origin Energy')
    end

    it 'returns "Sentinel Property Group" for names containing "Sentinel Property Group"' do
      expect(described_class.new('Sentinel Property Group').call).to eq('Sentinel Property Group')
    end

    it 'returns "Chevron Australia Pty Ltd" for names containing "Chevron Australia"' do
      expect(described_class.new('Chevron Australia').call).to eq('Chevron Australia Pty Ltd')
    end

    it 'returns "Inpex Corporation" for names containing "Inpex"' do
      expect(described_class.new('Inpex').call).to eq('Inpex Corporation')
    end

    it 'returns "Barton Deakin Pty Ltd" for names containing "Barton Deakin"' do
      expect(described_class.new('Barton Deakin').call).to eq('Barton Deakin Pty Ltd')
    end

    it 'returns "Mineralogy Pty Ltd" for names containing "Mineralogy"' do
      expect(described_class.new('Mineralogy').call).to eq('Mineralogy Pty Ltd')
    end

    it 'returns "Bluescope Steel Limited" for names containing "Bluescope Steel"' do
      expect(described_class.new('Bluescope Steel').call).to eq('Bluescope Steel Limited')
    end

    it 'returns "Gilbert & Tobin" for names containing "Gilbert & Tobin"' do
      expect(described_class.new('Gilbert & Tobin').call).to eq('Gilbert & Tobin')
      expect(described_class.new('Gilbert and Tobin').call).to eq('Gilbert & Tobin')
    end

    it 'returns "JMR Management Consultancy Services Pty Ltd" for names containing "JMR Management Consultancy"' do
      expect(described_class.new('JMR Management Consultancy').call).to eq('JMR Management Consultancy Services Pty Ltd')
    end

    it 'returns "NIB Health Funds Limited" for names containing "NIB Health Funds"' do
      expect(described_class.new('NIB Health Funds').call).to eq('NIB Health Funds Limited')
    end

        it 'returns "Origin Energy" for names containing "Origin Energy"' do
      expect(described_class.new('Origin Energy').call).to eq('Origin Energy')
    end

    it 'returns "Pricewaterhousecoopers" for names containing "Pricewaterhousecoopers"' do
      expect(described_class.new('Pricewaterhousecoopers').call).to eq('Pricewaterhousecoopers')
    end

    it 'returns "CMAX Advisory" for names containing "CMAX Advisory" or "CMAX Communications"' do
      expect(described_class.new('CMAX Advisory').call).to eq('CMAX Advisory')
      expect(described_class.new('CMAX Communications').call).to eq('CMAX Advisory')
    end

    it 'returns "Corporate Affairs Australia Pty Ltd" for names containing "Corporate Affairs Australia Pty Ltd" or "Corporate Affairs Advisory"' do
      expect(described_class.new('Corporate Affairs Australia Pty Ltd').call).to eq('Corporate Affairs Australia Pty Ltd')
      expect(described_class.new('Corporate Affairs Advisory').call).to eq('Corporate Affairs Australia Pty Ltd')
    end

    it 'returns "Hawker Britton Pty Ltd" for names containing "Hawker Britton Pty Ltd"' do
      expect(described_class.new('Hawker Britton Pty Ltd').call).to eq('Hawker Britton Pty Ltd')
    end

    it 'returns "Pacific Partners Strategic Advocacy Pty Ltd" for names containing "Pacific Partners Strategic Advocacy Pty Ltd"' do
      expect(described_class.new('Pacific Partners Strategic Advocacy Pty Ltd').call).to eq('Pacific Partners Strategic Advocacy Pty Ltd')
    end

    it 'returns "Probity International Pty Ltd" for names containing "Probity International Pty Ltd"' do
      expect(described_class.new('Probity International Pty Ltd').call).to eq('Probity International Pty Ltd')
    end

    it 'returns "The Pharmacy Guild of Australia" for names containing "Pharmacy Guild"' do
      expect(described_class.new('Pharmacy Guild').call).to eq('The Pharmacy Guild of Australia')
    end

    it 'returns "Your Solutions Compounding Pharmacy" for names containing "Your Solutions Compounding Pharmacy"' do
      expect(described_class.new('Your Solutions Compounding Pharmacy').call).to eq('Your Solutions Compounding Pharmacy')
    end

    it 'returns "AGL Energy Limited" for names equal to "AGL"' do
      expect(described_class.new('AGL').call).to eq('AGL Energy Limited')
    end

    it 'returns "AIA Australia" for names equal to "AIA"' do
      expect(described_class.new('AIA').call).to eq('AIA Australia')
    end

    it 'returns "AMP Limited" for names equal to "AMP"' do
      expect(described_class.new('AMP').call).to eq('AMP Limited')
    end

    it 'returns "Abbott Medical Australia Pty Ltd" for names equal to "Abbott"' do
      expect(described_class.new('Abbott').call).to eq('Abbott Medical Australia Pty Ltd')
    end

    it 'returns "Abbvie Australia" for names containing "Abbvie"' do
      expect(described_class.new('Abbvie').call).to eq('Abbvie Australia')
    end

    it 'returns "Adecco Australia" for names containing "Adecco Australia"' do
      expect(described_class.new('Adecco Australia').call).to eq('Adecco Australia')
    end

    it 'returns "Afterpay Australia Pty Ltd" for names containing "Afterpay Pty Ltd"' do
      expect(described_class.new('Afterpay Pty Ltd').call).to eq('Afterpay Australia Pty Ltd')
    end

    it 'returns "Agripower Australia Limited" for names containing "Agripower"' do
      expect(described_class.new('Agripower').call).to eq('Agripower Australia Limited')
    end

    it 'returns "Amazon Web Services Australia Pty Ltd" for names containing "Amazon Web Services Australia" or "Amazon AWS WEB Services Australia Pty Ltd"' do
      expect(described_class.new('Amazon Web Services Australia').call).to eq('Amazon Web Services Australia Pty Ltd')
      expect(described_class.new('Amazon AWS WEB Services Australia Pty Ltd').call).to eq('Amazon Web Services Australia Pty Ltd')
    end

    it 'returns "Amazon Web Services Limited" for names containing "Amazon Web Services"' do
      expect(described_class.new('Amazon Web Services').call).to eq('Amazon Web Services Limited')
    end

    it 'returns "Amazon Australia" for names containing "Amazon"' do
      expect(described_class.new('Amazon').call).to eq('Amazon Australia')
    end

    it 'returns "Amgen Australia Pty Ltd" for names containing "Amgen Australia"' do
      expect(described_class.new('Amgen Australia').call).to eq('Amgen Australia Pty Ltd')
    end

    it 'returns "Ampol Limited" for names containing "Ampol Ltd" or "Ampol Limited"' do
      expect(described_class.new('Ampol Ltd').call).to eq('Ampol Limited')
      expect(described_class.new('Ampol Limited').call).to eq('Ampol Limited')
    end

    it 'returns "Angus Knight Group" for names containing "Angus Knight Group", "Angus Knight Pty Ltd", or "Angus Knight Pty Limited"' do
      expect(described_class.new('Angus Knight Group').call).to eq('Angus Knight Group')
      expect(described_class.new('Angus Knight Pty Ltd').call).to eq('Angus Knight Group')
      expect(described_class.new('Angus Knight Pty Limited').call).to eq('Angus Knight Group')
    end

it 'returns "Arafura Rare Earths" for names containing "Arafura Rare Earths" or "Arafura Resources"' do
      expect(described_class.new('Arafura Rare Earths').call).to eq('Arafura Rare Earths')
      expect(described_class.new('Arafura Resources').call).to eq('Arafura Rare Earths')
    end

    it 'returns "Ausbiotech" for names containing "Ausbiotech"' do
      expect(described_class.new('Ausbiotech').call).to eq('Ausbiotech')
    end

    it 'returns "Australian Capital Equity Pty Ltd" for names containing "Australian Capital Equity Pty Ltd" or "Australian Capital Equity P/L"' do
      expect(described_class.new('Australian Capital Equity Pty Ltd').call).to eq('Australian Capital Equity Pty Ltd')
      expect(described_class.new('Australian Capital Equity P/L').call).to eq('Australian Capital Equity Pty Ltd')
    end

    it 'returns "Australian Computer Society" for names containing "Australian Computer Society Incorporated"' do
      expect(described_class.new('Australian Computer Society Incorporated').call).to eq('Australian Computer Society')
    end

    it 'returns "BP Australia Pty Ltd" for names containing "BP Australia Pty Ltd" or equal to "BP Australia"' do
      expect(described_class.new('BP Australia Pty Ltd').call).to eq('BP Australia Pty Ltd')
      expect(described_class.new('BP Australia').call).to eq('BP Australia Pty Ltd')
    end

    it 'returns "Bayer Australia Ltd" for names containing "Bayer Australia Ltd" or "Bayer Australia Limited"' do
      expect(described_class.new('Bayer Australia Ltd').call).to eq('Bayer Australia Ltd')
      expect(described_class.new('Bayer Australia Limited').call).to eq('Bayer Australia Ltd')
    end

    it 'returns "Beach Energy Limited" for names containing "Beach Energy"' do
      expect(described_class.new('Beach Energy').call).to eq('Beach Energy Limited')
    end

    it 'returns "Bowen Coking Coal" for names containing "Bowen Coking Coal"' do
      expect(described_class.new('Bowen Coking Coal').call).to eq('Bowen Coking Coal')
    end

    it 'returns "Bus Association of Victoria" for names containing "Bus Association of Victoria"' do
      expect(described_class.new('Bus Association of Victoria').call).to eq('Bus Association of Victoria')
    end

    it 'returns "CAE Australia Pty Ltd" for names containing "CAE Australia" or equal to "CAE"' do
      expect(described_class.new('CAE Australia').call).to eq('CAE Australia Pty Ltd')
      expect(described_class.new('CAE').call).to eq('CAE Australia Pty Ltd')
    end

    it 'returns "CO2CRC" for names containing "CO2CRC"' do
      expect(described_class.new('CO2CRC').call).to eq('CO2CRC')
    end

    it 'returns "Canberra Consulting" for names containing "Canberra Consulting"' do
      expect(described_class.new('Canberra Consulting').call).to eq('Canberra Consulting')
    end

    it 'returns "Careflight" for names containing "Careflight"' do
      expect(described_class.new('Careflight').call).to eq('Careflight')
    end

    it 'returns "Chevron Australia Pty Ltd" for names containing "Chevron"' do
      expect(described_class.new('Chevron').call).to eq('Chevron Australia Pty Ltd')
    end

    it 'returns "Citigroup" for names containing "Citigroup"' do
      expect(described_class.new('Citigroup').call).to eq('Citigroup')
    end

    it 'returns "Civmec Construction & Engineering Pty Ltd" for names containing "Civmec Construction & Engineering"' do
      expect(described_class.new('Civmec Construction & Engineering').call).to eq('Civmec Construction & Engineering Pty Ltd')
    end

    it 'returns "Conocophillips Australia Pty Ltd" for names containing "Conocophillips"' do
      expect(described_class.new('Conocophillips').call).to eq('Conocophillips Australia Pty Ltd')
    end

    it 'returns "Consolidated Properties Group" for names containing "Consolidated Properties Group" or equal to "Consolidated Properties"' do
      expect(described_class.new('Consolidated Properties Group').call).to eq('Consolidated Properties Group')
      expect(described_class.new('Consolidated Properties').call).to eq('Consolidated Properties Group')
    end

    it 'returns "Cooper Energy Ltd" for names containing "Cooper Energy Ltd" or equal to "Cooper Energy"' do
      expect(described_class.new('Cooper Energy Ltd').call).to eq('Cooper Energy Ltd')
      expect(described_class.new('Cooper Energy').call).to eq('Cooper Energy Ltd')
    end

    it 'returns "Delaware North" for names containing "Delaware North"' do
      expect(described_class.new('Delaware North').call).to eq('Delaware North')
    end

    it 'returns "Dell Australia Pty Ltd" for names containing "Dell Australia" or "Dell Technologies"' do
      expect(described_class.new('Dell Australia').call).to eq('Dell Australia Pty Ltd')
      expect(described_class.new('Dell Technologies').call).to eq('Dell Australia Pty Ltd')
    end

    it 'returns "Diageo Australia Limited" for names containing "Diageo Australia"' do
      expect(described_class.new('Diageo Australia').call).to eq('Diageo Australia Limited')
    end

    it 'returns "Droneshield Limited" for names containing "Droneshield"' do
      expect(described_class.new('Droneshield').call).to eq('Droneshield Limited')
    end

    it 'returns "Echostar Global Australia Pty Ltd" for names containing "Echostar"' do
      expect(described_class.new('Echostar').call).to eq('Echostar Global Australia Pty Ltd')
    end

    it 'returns "Edwards Lifesciences Pty Ltd" for names containing "Edwards Lifesciences" or "Edwards Life"' do
      expect(described_class.new('Edwards Lifesciences').call).to eq('Edwards Lifesciences Pty Ltd')
      expect(described_class.new('Edwards Life').call).to eq('Edwards Lifesciences Pty Ltd')
    end

    it 'returns "Elbit Systems of Australia P/L" for names containing "Elbit Systems of Australia"' do
      expect(described_class.new('Elbit Systems of Australia').call).to eq('Elbit Systems of Australia P/L')
    end

    it 'returns "Electro Optic Systems Pty Ltd" for names containing "Electro Optic Systems"' do
      expect(described_class.new('Electro Optic Systems').call).to eq('Electro Optic Systems Pty Ltd')
    end

    it 'returns "Eli Lilly Australia Pty Ltd" for names containing "Eli Lilly Australia" or equal to "Eli Lilly"' do
      expect(described_class.new('Eli Lilly Australia').call).to eq('Eli Lilly Australia Pty Ltd')
      expect(described_class.new('Eli Lilly').call).to eq('Eli Lilly Australia Pty Ltd')
    end

    it 'returns "Environmental Defense Fund" for names containing "Environmental Defense Fund"' do
      expect(described_class.new('Environmental Defense Fund').call).to eq('Environmental Defense Fund')
    end

    it 'returns "Equinor Australia" for names containing "Equinor Australia" or equal to "Equinor"' do
      expect(described_class.new('Equinor Australia').call).to eq('Equinor Australia')
      expect(described_class.new('Equinor').call).to eq('Equinor Australia')
    end

    it 'returns "Ernst & Young" for names containing "Ernst & Young"' do
      expect(described_class.new('Ernst & Young').call).to eq('Ernst & Young')
    end

    it 'returns "Eusa Pharma (Australia) Pty Ltd" for names containing "Eusa Pharma (Australia) Pty Ltd" or equal to "Eusa Pharma"' do
      expect(described_class.new('Eusa Pharma (Australia) Pty Ltd').call).to eq('Eusa Pharma (Australia) Pty Ltd')
      expect(described_class.new('Eusa Pharma').call).to eq('Eusa Pharma (Australia) Pty Ltd')
    end

    it 'returns "Expedia Australia Pty Ltd" for names containing "Expedia Australia Pty Ltd" or equal to "Expedia"' do
      expect(described_class.new('Expedia Australia Pty Ltd').call).to eq('Expedia Australia Pty Ltd')
      expect(described_class.new('Expedia').call).to eq('Expedia Australia Pty Ltd')
    end

    it 'returns "Field and Game Australia" for names containing "Field and Game Australia"' do
      expect(described_class.new('Field and Game Australia').call).to eq('Field and Game Australia')
    end

    it 'returns "Football Australia" for names containing "Football Australia Limited" or equal to "Football Australia"' do
      expect(described_class.new('Football Australia Limited').call).to eq('Football Australia')
      expect(described_class.new('Football Australia').call).to eq('Football Australia')
    end

    it 'returns "Fortem Australia Limited" for names containing "Fortem Australia Limited" or equal to "Fortem Australia"' do
      expect(described_class.new('Fortem Australia Limited').call).to eq('Fortem Australia Limited')
      expect(described_class.new('Fortem Australia').call).to eq('Fortem Australia Limited')
    end

    it 'returns "Free TV Australia Limited" for names containing "Free TV Australia" or "FreeTV Australia"' do
      expect(described_class.new('Free TV Australia').call).to eq('Free TV Australia Limited')
      expect(described_class.new('FreeTV Australia').call).to eq('Free TV Australia Limited')
    end

    it 'returns "Frisk - Search Pty Ltd" for names containing "Frisk" and "Search"' do
      expect(described_class.new('Frisk Search').call).to eq('Frisk - Search Pty Ltd')
      expect(described_class.new('Frisk and Search').call).to eq('Frisk - Search Pty Ltd')
    end

    it 'returns "From the Fields Pharmaceuticals Australia Pty Ltd" for names containing "From The Fields"' do
      expect(described_class.new('From The Fields').call).to eq('From the Fields Pharmaceuticals Australia Pty Ltd')
    end

    it 'returns "Fugro Australia Pty Ltd" for names containing "Fugro Australia" or equal to "Fugro"' do
      expect(described_class.new('Fugro Australia').call).to eq('Fugro Australia Pty Ltd')
      expect(described_class.new('Fugro').call).to eq('Fugro Australia Pty Ltd')
    end

    it 'returns "GB Energy Holdings Pty Ltd" for names containing "GB Energy Holdings" or equal to "GB Energy"' do
      expect(described_class.new('GB Energy Holdings').call).to eq('GB Energy Holdings Pty Ltd')
      expect(described_class.new('GB Energy').call).to eq('GB Energy Holdings Pty Ltd')
    end

    it 'returns "Gascoyne Gateway Limited" for names containing "Gascoyne Gateway Limited"' do
      expect(described_class.new('Gascoyne Gateway Limited').call).to eq('Gascoyne Gateway Limited')
    end

    it 'returns "Gedeon Richter Australia Pty Ltd" for names containing "Gedeon Richter Australia"' do
      expect(described_class.new('Gedeon Richter Australia').call).to eq('Gedeon Richter Australia Pty Ltd')
    end

    it 'returns "Gilmour Space Technologies Pty Ltd" for names containing "Gilmour Space Technologies"' do
      expect(described_class.new('Gilmour Space Technologies').call).to eq('Gilmour Space Technologies Pty Ltd')
    end

    it 'returns "Gippsland Critical Minerals" for names containing "Gippsland Critical Minerals"' do
      expect(described_class.new('Gippsland Critical Minerals').call).to eq('Gippsland Critical Minerals')
    end

    it 'returns "Glengarry Advisory Pty Ltd" for names containing "Glengarry Advisory"' do
      expect(described_class.new('Glengarry Advisory').call).to eq('Glengarry Advisory Pty Ltd')
    end

    it 'returns "Golf Australia Limited" for names containing "Golf Australia Limited" or "Golf Australia Ltd"' do
      expect(described_class.new('Golf Australia Limited').call).to eq('Golf Australia Limited')
      expect(described_class.new('Golf Australia Ltd').call).to eq('Golf Australia Limited')
    end

    it 'returns "Google Australia Pty Ltd" for names containing "Google Australia"' do
      expect(described_class.new('Google Australia').call).to eq('Google Australia Pty Ltd')
    end

    it 'returns "Group of 100" for names containing "Group of 100"' do
      expect(described_class.new('Group of 100').call).to eq('Group of 100')
    end

    it 'returns "Gulanga Group" for names containing "Gulanga Group"' do
      expect(described_class.new('Gulanga Group').call).to eq('Gulanga Group')
    end

    it 'returns "Heartland Solutions Group" for names containing "Heartland Solutions Group"' do
      expect(described_class.new('Heartland Solutions Group').call).to eq('Heartland Solutions Group')
    end

    it 'returns "Holmes Institute" for names containing "Holmes Institute"' do
      expect(described_class.new('Holmes Institute').call).to eq('Holmes Institute')
    end

    it 'returns "Holmwood Highgate Pty Ltd" for names containing "Holmwood Highgate"' do
      expect(described_class.new('Holmwood Highgate').call).to eq('Holmwood Highgate Pty Ltd')
    end

it 'returns "Idemitsu Australia Pty Ltd" for names containing "Idemitsu Australia"' do
      expect(described_class.new('Idemitsu Australia').call).to eq('Idemitsu Australia Pty Ltd')
    end

    it 'returns "Inghams Group Limited" for names containing "Inghams Group Limited" or equal to "Inghams"' do
      expect(described_class.new('Inghams Group Limited').call).to eq('Inghams Group Limited')
      expect(described_class.new('Inghams').call).to eq('Inghams Group Limited')
    end

    it 'returns "Insurance Council of Australia" for names containing "Insurance Council of Australia"' do
      expect(described_class.new('Insurance Council of Australia').call).to eq('Insurance Council of Australia')
    end

    it 'returns "Intech Strategies P/L" for names containing "Intech Strategies"' do
      expect(described_class.new('Intech Strategies').call).to eq('Intech Strategies P/L')
    end

    it 'returns "Ipsen Pty Ltd" for names containing "Ipsen Pty Ltd" or equal to "Ipsen"' do
      expect(described_class.new('Ipsen Pty Ltd').call).to eq('Ipsen Pty Ltd')
      expect(described_class.new('Ipsen').call).to eq('Ipsen Pty Ltd')
    end

    it 'returns "Israel Aerospace Industries Limited" for names containing "Israel Aerospace Industries Limited" or equal to "Ipsen"' do
      expect(described_class.new('Israel Aerospace Industries Limited').call).to eq('Israel Aerospace Industries Limited')
    end

    it 'returns "JERA Australia Pty Ltd" for names containing "JERA Australia" or equal to "Jera"' do
      expect(described_class.new('JERA Australia').call).to eq('JERA Australia Pty Ltd')
      expect(described_class.new('Jera').call).to eq('JERA Australia Pty Ltd')
    end

    it 'returns "Jellinbah Group" for names containing "Jellinbah Group"' do
      expect(described_class.new('Jellinbah Group').call).to eq('Jellinbah Group')
    end

    it 'returns "Johnson & Johnson Medical" for names containing "Johnson & Johnson Medical"' do
      expect(described_class.new('Johnson & Johnson Medical').call).to eq('Johnson & Johnson Medical')
      expect(described_class.new('Johnson And Johnson Medical').call).to eq('Johnson & Johnson Medical')
    end

    it 'returns "Johnson & Johnson Pty Ltd" for names containing "Johnson & Johnson"' do
      expect(described_class.new('Johnson & Johnson').call).to eq('Johnson & Johnson Pty Ltd')
      expect(described_class.new('Johnson And Johnson').call).to eq('Johnson & Johnson Pty Ltd')
    end

    it 'returns "KPMG Australia" for names containing "KPMG Australia" or equal to "KPMG"' do
      expect(described_class.new('KPMG Australia').call).to eq('KPMG Australia')
      expect(described_class.new('KPMG').call).to eq('KPMG Australia')
    end

    it 'returns "Kimberly-Clark Australia Pty Ltd" for names containing "Kimberly-Clark Australia" or "KimberlyClark"' do
      expect(described_class.new('Kimberly-Clark Australia').call).to eq('Kimberly-Clark Australia Pty Ltd')
      expect(described_class.new('KimberlyClark').call).to eq('Kimberly-Clark Australia Pty Ltd')
    end

    it 'returns "L3 Harris Technologies" for names containing "L3 Harris Technologies" or "L3Harris Technologies"' do
      expect(described_class.new('L3 Harris Technologies').call).to eq('L3 Harris Technologies')
      expect(described_class.new('L3Harris Technologies').call).to eq('L3 Harris Technologies')
    end

    it 'returns "Lendlease Australia Pty Ltd" for names containing "Lendlease Australia" or "Lendlease Pty Ltd"' do
      expect(described_class.new('Lendlease Australia').call).to eq('Lendlease Australia Pty Ltd')
      expect(described_class.new('Lendlease Pty Ltd').call).to eq('Lendlease Australia Pty Ltd')
    end

    it 'returns "Lion Pty Ltd" for names equal to "lion"' do
      expect(described_class.new('lion').call).to eq('Lion Pty Ltd')
    end

    it 'returns "Lockheed Martin Australia Pty Ltd" for names containing "Lockheed Martin Australia"' do
      expect(described_class.new('Lockheed Martin Australia').call).to eq('Lockheed Martin Australia Pty Ltd')
    end

    it 'returns "Matrix Composites & Engineering" for names containing "Matrix Composites & Engineering"' do
      expect(described_class.new('Matrix Composites & Engineering').call).to eq('Matrix Composites & Engineering')
    end

    it 'returns "Merck Healthcare" for names containing "Merck Healthcare"' do
      expect(described_class.new('Merck Healthcare').call).to eq('Merck Healthcare')
    end

    it 'returns "Metallicum Minerals Corporation" for names containing "Metallicum Minerals Corporation"' do
      expect(described_class.new('Metallicum Minerals Corporation').call).to eq('Metallicum Minerals Corporation')
    end

    it 'returns "National Retail Association Limited" for names containing "National Retail Association"' do
      expect(described_class.new('National Retail Association').call).to eq('National Retail Association Limited')
    end

    it 'returns "Nestle Australia" for names containing "Nestle Australia"' do
      expect(described_class.new('Nestle Australia').call).to eq('Nestle Australia')
    end

    it 'returns "Netapp Pty Ltd" for names containing "Netapp Pty Ltd" or equal to "Netapp"' do
      expect(described_class.new('Netapp Pty Ltd').call).to eq('Netapp Pty Ltd')
      expect(described_class.new('Netapp').call).to eq('Netapp Pty Ltd')
    end

    it 'returns "Novo Nordisk Pharmaceuticals Pty Ltd" for names containing "Novo Nordisk Pharmaceuticals"' do
      expect(described_class.new('Novo Nordisk Pharmaceuticals').call).to eq('Novo Nordisk Pharmaceuticals Pty Ltd')
    end

    it 'returns "Orion Sovereign Group Pty Ltd" for names containing "Orion Sovereign Group"' do
      expect(described_class.new('Orion Sovereign Group').call).to eq('Orion Sovereign Group Pty Ltd')
    end

    it 'returns "PainAustralia Limited" for names containing "PainAustralia"' do
      expect(described_class.new('PainAustralia').call).to eq('PainAustralia Limited')
    end

    it 'returns "Paintback Limited" for names containing "Paintback"' do
      expect(described_class.new('Paintback').call).to eq('Paintback Limited')
    end

    it 'returns "Pathology Technology Australia" for names containing "Pathology Technology Australia"' do
      expect(described_class.new('Pathology Technology Australia').call).to eq('Pathology Technology Australia')
    end

    it 'returns "Penten Pty Ltd" for names containing "Penten Pty Ltd" or equal to "Penten"' do
      expect(described_class.new('Penten Pty Ltd').call).to eq('Penten Pty Ltd')
      expect(described_class.new('Penten').call).to eq('Penten Pty Ltd')
    end

    it 'returns "Playgroups Australia" for names containing "Playgroups Australia"' do
      expect(described_class.new('Playgroups Australia').call).to eq('Playgroups Australia')
    end

    it 'returns "Pratt Holdings Pty Ltd" for names containing "Pratt Holdings"' do
      expect(described_class.new('Pratt Holdings').call).to eq('Pratt Holdings Pty Ltd')
    end

    it 'returns "RES Australia Pty Ltd" for names containing "RES Australia" or "RES Australia Pty Ltd"' do
      expect(described_class.new('RES Australia').call).to eq('RES Australia Pty Ltd')
      expect(described_class.new('RES Australia Pty Ltd').call).to eq('RES Australia Pty Ltd')
    end

    it 'returns "RZ Resources Limited" for names containing "RZ Resources Limited" or "RZ Resources Ltd"' do
      expect(described_class.new('RZ Resources Limited').call).to eq('RZ Resources Limited')
      expect(described_class.new('RZ Resources Ltd').call).to eq('RZ Resources Limited')
    end

    it 'returns "Ramsay Health Care Limited" for names containing "Ramsay Health Care"' do
      expect(described_class.new('Ramsay Health Care').call).to eq('Ramsay Health Care Limited')
    end

    it 'returns "Rare Cancers Australia" for names containing "Rare Cancers Australia"' do
      expect(described_class.new('Rare Cancers Australia').call).to eq('Rare Cancers Australia')
    end

    it 'returns "Ryman Healthcare (Australia) Pty Ltd" for names containing "Ryman Healthcare Australia" or equal to "ryman healthcare"' do
      expect(described_class.new('Ryman Healthcare Australia').call).to eq('Ryman Healthcare (Australia) Pty Ltd')
      expect(described_class.new('ryman healthcare').call).to eq('Ryman Healthcare (Australia) Pty Ltd')
    end

    it 'returns "SA Milgate and Associates Pty Ltd" for names containing "SA Milgate and Associates"' do
      expect(described_class.new('SA Milgate and Associates').call).to eq('SA Milgate and Associates Pty Ltd')
    end

    it 'returns "ST John of GOD Healthcare" for names containing "ST John of GOD Healthcare" or "ST John of GOD Health Care"' do
      expect(described_class.new('ST John of GOD Healthcare').call).to eq('ST John of GOD Healthcare')
      expect(described_class.new('ST John of GOD Health Care').call).to eq('ST John of GOD Healthcare')
    end

    it 'returns "Saab Australia Pty Ltd" for names containing "Saab Australia Pty Ltd" or equal to "saab"' do
      expect(described_class.new('Saab Australia Pty Ltd').call).to eq('Saab Australia Pty Ltd')
      expect(described_class.new('saab').call).to eq('Saab Australia Pty Ltd')
    end

    it 'returns "Settlement Services International" for names containing "Settlement Services International"' do
      expect(described_class.new('Settlement Services International').call).to eq('Settlement Services International')
    end

    it 'returns "Shop Distributive & Allied Employees Association - National" for names containing "Shop Distributive & Allied Employees Association - National" or similar variations' do
      expect(described_class.new('Shop Distributive & Allied Employees Association - National').call).to eq("Shop Distributive & Allied Employees Association - National'")
      expect(described_class.new('Shop and Allied Employees Association National').call).to eq("Shop Distributive & Allied Employees Association - National'")
    end

    it 'returns "SMEC Australia Pty Ltd" for names containing "SMEC Australia"' do
      expect(described_class.new('SMEC Australia').call).to eq('SMEC Australia Pty Ltd')
    end

    it 'returns "Sovori Pty Ltd ATF the Sovori Trust" for names containing "Sovori Pty Ltd"' do
      expect(described_class.new('Sovori Pty Ltd').call).to eq('Sovori Pty Ltd ATF the Sovori Trust')
    end

    it 'returns "Space Machines Company" for names containing "Space Machines Company"' do
      expect(described_class.new('Space Machines Company').call).to eq('Space Machines Company')
    end

    it 'returns "Speedcast Australia Pty Ltd" for names containing "Speedcast Australia Pty Ltd" or equal to "Speedcast"' do
      expect(described_class.new('Speedcast Australia Pty Ltd').call).to eq('Speedcast Australia Pty Ltd')
      expect(described_class.new('Speedcast').call).to eq('Speedcast Australia Pty Ltd')
    end

    it 'returns "Spirits & Cocktails Australia" for names containing "Spirits & Cocktails Australia" or "Spirits and Cocktails Australia"' do
      expect(described_class.new('Spirits & Cocktails Australia').call).to eq('Spirits & Cocktails Australia')
      expect(described_class.new('Spirits and Cocktails Australia').call).to eq('Spirits & Cocktails Australia')
    end

    it 'returns "Springfield City Group" for names containing "Springfield City Group"' do
      expect(described_class.new('Springfield City Group').call).to eq('Springfield City Group')
    end

    it 'returns "Standbyu Foundation" for names containing "Standbyu Foundation"' do
      expect(described_class.new('Standbyu Foundation').call).to eq('Standbyu Foundation')
    end

    it 'returns "Stryker Australia Pty Ltd" for names containing "Stryker Australia Pty Ltd" or equal to "stryker"' do
      expect(described_class.new('Stryker Australia Pty Ltd').call).to eq('Stryker Australia Pty Ltd')
      expect(described_class.new('stryker').call).to eq('Stryker Australia Pty Ltd')
    end

    it 'returns "Strzelecki Holdings Pty Ltd" for names containing "Strzelecki Holdings Pty Ltd" or "Strzelecki Holding Pty Ltd"' do
      expect(described_class.new('Strzelecki Holdings Pty Ltd').call).to eq('Strzelecki Holdings Pty Ltd')
      expect(described_class.new('Strzelecki Holding Pty Ltd').call).to eq('Strzelecki Holdings Pty Ltd')
    end

    it 'returns "Sumitomo Corporation" for names containing "Sumitomo Corporation" or "Sumitom Corporation"' do
      expect(described_class.new('Sumitomo Corporation').call).to eq('Sumitomo Corporation')
      expect(described_class.new('Sumitom Corporation').call).to eq('Sumitomo Corporation')
    end

    it 'returns "Ted Noffs Foundation" for names containing "TED Noffs Foundation"' do
      expect(described_class.new('TED Noffs Foundation').call).to eq('Ted Noffs Foundation')
    end

    it 'returns "Tellus Holdings Ltd" for names containing "Tellus Holdings"' do
      expect(described_class.new('Tellus Holdings').call).to eq('Tellus Holdings Ltd')
    end

    it 'returns "Telstra Corporation" for names containing "Telstra Corporation" or equal to "telstra"' do
      expect(described_class.new('Telstra Corporation').call).to eq('Telstra Corporation')
      expect(described_class.new('telstra').call).to eq('Telstra Corporation')
    end

    it 'returns "The Alannah & Madeline Foundation" for names containing "The Alannah & Madeline Foundation" or "The Alannah and Madeline Foundation"' do
      expect(described_class.new('The Alannah & Madeline Foundation').call).to eq('The Alannah & Madeline Foundation')
      expect(described_class.new('The Alannah and Madeline Foundation').call).to eq('The Alannah & Madeline Foundation')
    end

    it 'returns "The Premier Communications Group" for names containing "The Premier Communications Group"' do
      expect(described_class.new('The Premier Communications Group').call).to eq('The Premier Communications Group')
    end

    it 'returns "The Union Education Foundation" for names containing "The Union Education Foundation"' do
      expect(described_class.new('The Union Education Foundation').call).to eq('The Union Education Foundation')
    end

    it 'returns "Trademark Group of Companies" for names containing "Trademark Group of Companies"' do
      expect(described_class.new('Trademark Group of Companies').call).to eq('Trademark Group of Companies')
    end

    it 'returns "Trafigura" for names containing "Trafigura Pte Ltd" or equal to "trafigura"' do
      expect(described_class.new('Trafigura Pte Ltd').call).to eq('Trafigura')
      expect(described_class.new('trafigura').call).to eq('Trafigura')
    end

    it 'returns "Tronox Limited" for names containing "Tronox Limited" or "Tronox Ltd"' do
      expect(described_class.new('Tronox Limited').call).to eq('Tronox Limited')
      expect(described_class.new('Tronox Ltd').call).to eq('Tronox Limited')
    end

    it 'returns "UCB Australia Pty Ltd" for names containing "UCB Australia Pty Ltd" or "UCB Australia Proprietary Limited"' do
      expect(described_class.new('UCB Australia Pty Ltd').call).to eq('UCB Australia Pty Ltd')
      expect(described_class.new('UCB Australia Proprietary Limited').call).to eq('UCB Australia Pty Ltd')
    end

    it 'returns "Uber Australia Pty Ltd" for names containing "Uber Australia Pty Ltd" or equal to "uber"' do
      expect(described_class.new('Uber Australia Pty Ltd').call).to eq('Uber Australia Pty Ltd')
      expect(described_class.new('uber').call).to eq('Uber Australia Pty Ltd')
    end

    it 'returns "Van Dairy Ltd" for names containing "Van Dairy Ltd" or "vanmilk"' do
      expect(described_class.new('Van Dairy Ltd').call).to eq('Van Dairy Ltd')
      expect(described_class.new('vanmilk').call).to eq('Van Dairy Ltd')
    end

    it 'returns "Varley Rafael Australia" for names containing "Varley Rafael Australia" or equal to "varley rafael"' do
      expect(described_class.new('Varley Rafael Australia').call).to eq('Varley Rafael Australia')
      expect(described_class.new('varley rafael').call).to eq('Varley Rafael Australia')
    end

    it 'returns "Verbrec Ltd" for names containing "Verbrec Ltd" or "Verbrec Limited" or equal to "verbrec"' do
      expect(described_class.new('Verbrec Ltd').call).to eq('Verbrec Ltd')
      expect(described_class.new('Verbrec Limited').call).to eq('Verbrec Ltd')
      expect(described_class.new('verbrec').call).to eq('Verbrec Ltd')
    end

    it 'returns "Verdant Minerals" for names containing "Verdant Minerals"' do
      expect(described_class.new('Verdant Minerals').call).to eq('Verdant Minerals')
    end

    it 'returns "Vertex Pharmaceuticals Australia Pty Ltd" for names containing "Vertex Pharmaceuticals Australia"' do
      expect(described_class.new('Vertex Pharmaceuticals Australia').call).to eq('Vertex Pharmaceuticals Australia Pty Ltd')
    end

    it 'returns "Victorian Hydrogen and Ammonia Industries Limited" for names containing "Victorian Hydrogen and Ammonia Industries" or "Victorian Hydrogen & Ammonia Industries"' do
      expect(described_class.new('Victorian Hydrogen and Ammonia Industries').call).to eq('Victorian Hydrogen and Ammonia Industries Limited')
      expect(described_class.new('Victorian Hydrogen & Ammonia Industries').call).to eq('Victorian Hydrogen and Ammonia Industries Limited')
    end

    it 'returns "Wesfarmers Limited" for names containing "Wesfarmers Limited" or "Wesfarmers Ltd" or equal to "wesfarmers"' do
      expect(described_class.new('Wesfarmers Limited').call).to eq('Wesfarmers Limited')
      expect(described_class.new('Wesfarmers Ltd').call).to eq('Wesfarmers Limited')
      expect(described_class.new('wesfarmers').call).to eq('Wesfarmers Limited')
    end

    it 'returns "Westpac Banking Corporation" for names containing "Westpac Banking Corporation" or equal to "westpac"' do
      expect(described_class.new('Westpac Banking Corporation').call).to eq('Westpac Banking Corporation')
      expect(described_class.new('westpac').call).to eq('Westpac Banking Corporation')
    end

    # it 'returns "Your (Solutions|Solution) Compounding Pharmacy" for names containing "Your Solutions Compounding Pharmacy"' do
    #   expect(described_class.new('Your Solutions Compounding Pharmacy').call).to eq('Your (Solutions|Solution) Compounding Pharmacy')
    # end

    it 'returns "Yumbah Aquaculture" for names containing "Yumbah Aquaculture"' do
      expect(described_class.new('Yumbah Aquaculture').call).to eq('Yumbah Aquaculture')
    end

    it 'returns "Clubs Australia" for names containing "ClubsAustralia Inc"' do
      expect(described_class.new('ClubsAustralia Inc').call).to eq('Clubs Australia')
    end

    it 'returns "Idameneo (No 123) Pty Ltd" for names containing "Idameneo No 123"' do
      expect(described_class.new('Idameneo No 123').call).to eq('Idameneo (No 123) Pty Ltd')
    end

    it 'returns "Schaffer Corporation Limited" for names containing "Schaffer Corporation Limited" or "Schaffer Corporation Ltd"' do
      expect(described_class.new('Schaffer Corporation Limited').call).to eq('Schaffer Corporation Limited')
      expect(described_class.new('Schaffer Corporation Ltd').call).to eq('Schaffer Corporation Limited')
    end

    it 'returns "The Union Education Foundation" for names containing "Union Education Foundation"' do
      expect(described_class.new('Union Education Foundation').call).to eq('The Union Education Foundation')
    end

    it 'returns "Tamboran Resources Limited" for names containing "Tamboran Resources"' do
      expect(described_class.new('Tamboran Resources').call).to eq('Tamboran Resources Limited')
    end

    it 'returns "Paladin Group" for names containing "Paladin Group"' do
      expect(described_class.new('Paladin Group').call).to eq('Paladin Group')
    end

    it 'returns "Qube Ports" for names containing "Qube Ports"' do
      expect(described_class.new('Qube Ports').call).to eq('Qube Ports')
    end

    it 'returns "Australian Energy Producers" for names containing "APPEA" or "Australian Energy Producers"' do
      expect(described_class.new('APPEA').call).to eq('Australian Energy Producers')
      expect(described_class.new('Australian Energy Producers').call).to eq('Australian Energy Producers')
    end

    context 'for smaller political parties' do
      it 'returns "Liberal Democratic Party" for names containing "Liberal Democrat"' do
        expect(described_class.new('Liberal Democrat').call).to eq('Liberal Democratic Party')
        expect(described_class.new('Liberal Democratic Party').call).to eq('Liberal Democratic Party')
      end

      it 'returns "Shooters, Fishers and Farmers Party" for names containing "Shooters, Fishers and Farmers"' do
        expect(described_class.new('Shooters, Fishers and Farmers').call).to eq('Shooters, Fishers and Farmers Party')
      end

      it 'returns "Citizens Party" for names containing "Citizens Party" or "CEC"' do
        expect(described_class.new('Citizens Party').call).to eq('Citizens Party')
        expect(described_class.new('CEC').call).to eq('Citizens Party')
      end

      it 'returns "Sustainable Australia Party" for names containing "Sustainable Australia"' do
        expect(described_class.new('Sustainable Australia').call).to eq('Sustainable Australia Party')
      end

      it 'returns "Centre Alliance" for names containing "Centre Alliance"' do
        expect(described_class.new('Centre Alliance').call).to eq('Centre Alliance')
      end

      it 'returns "The Local Party of Australia" for names containing "The Local Party of Australia"' do
        expect(described_class.new('The Local Party of Australia').call).to eq('The Local Party of Australia')
      end

      it 'returns "Katter Australia Party" for names containing "Katter Australia" or "KAP"' do
        expect(described_class.new('Katter Australia').call).to eq('Katter Australia Party')
        expect(described_class.new('KAP').call).to eq('Katter Australia Party')
      end

      it 'returns "Australian Conservatives" for names containing "Australian Conservatives"' do
        expect(described_class.new('Australian Conservatives').call).to eq('Australian Conservatives')
      end

      it 'returns "Federal Independents" for names containing "Independent Fed"' do
        expect(described_class.new('Independent Fed').call).to eq('Federal Independents')
      end

      it 'returns "Waringah Independents" for names containing "Warringah Independent" or "Waringah Independant"' do
        expect(described_class.new('Warringah Independent').call).to eq('Waringah Independents')
        expect(described_class.new('Waringah Independant').call).to eq('Waringah Independents')
      end

      it 'returns "Lambie Network" for names containing "Lambie"' do
        expect(described_class.new('Lambie').call).to eq('Lambie Network')
      end

      it 'returns "United Australia Party" for names containing "United Australia Party" or "United Australia Federal"' do
        expect(described_class.new('United Australia Party').call).to eq('United Australia Party')
        expect(described_class.new('United Australia Federal').call).to eq('United Australia Party')
      end

      it 'returns "Pauline Hanson\'s One Nation" for names containing "Pauline Hanson" or "One Nation"' do
        expect(described_class.new('Pauline Hanson').call).to eq("Pauline Hanson's One Nation")
        expect(described_class.new('One Nation').call).to eq("Pauline Hanson's One Nation")
      end
    end

    context 'for liberal party' do
      it 'returns lib federal' do
        expect(described_class.new('Liberal Party Menzies Research Centre').call).to eq('Liberals (Federal)')
      end

      it 'returns libs NSW' do
      end

      it 'returns libs QLD' do
      end

      it 'returns libs SA' do
      end

      it 'returns libs TAS' do
      end

      it 'returns libs WA' do
      end

      it 'returns libs VIC' do
      end
    end

    context 'for labor party' do
    end

    context 'for greens party' do
    end

    context 'for nationals party' do
    end
  end
end
