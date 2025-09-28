require 'capitalize_names'
class MapGroupNamesBase
  def cleaned_up_name(name)
    regex_for_two_and_three_chars = /(\b\w{2,3}\b)|(\b\w{2,3}\d)/
    regex_for_longer_acronyms_1 = /\bAENM\b|\bKPMG\b|\bAPAC\b|\bACCI\b|\bDBPC\b|\bCEPU\b|\bACDC\b|\bCFMEU\b/i
    regex_for_longer_acronyms_2 = /\bPESA\b|\bRISC\b|\bJERA\b|\bAMPD\b|\bAFTA\b|\bFTTH\b|\bGCFC\b|\bGIMC\b/i
    regex_for_longer_acronyms_3 = /\bCPSU\b|\bSPSF\b|\bCRRC\b|\bCSIROb|\bCTSI\b|\bERGT\b|\bGGBV\b|\bHSBC\b/i
    regex_for_longer_acronyms_4 = /\bCPAC\b/i

    regex_for_titleize = /\bPty\b|\bLtd\b|\bBus\b|\bInc\b|\bCo\b|\bTel\b|\bVan\b|\bAus\b|\bIan\b/i
    regex_for_titleize_2 = /\bMud\b\bWeb\b|\bNow\b|\bNo\b|\bTen\b|Eli lilly\b|\bNew\b|\bJob\b/i
    regex_for_titleize_3 = /\bDot\b|\bRex\b|\bTan\b|\bUmi\b|\bBig\b|\bDr\b|\bGas\b|\bOil\b/i
    regex_for_titleize_4 = /\bTax\b|\bAid\b|\bBay\b|\bTo\b|\bYes\b|\bRed\b|\bOne\b|\bSky\b/i
    regex_for_titleize_5 = /\bAmazon Web Services\b|\bAce Gutters\b|\bMud Guards\b|\bGum Tree\b|\bYe Family\b/i
    regex_for_titleize_6 = /\bRio Tinto\b|\bRed Rocketship\b|\bCar Park\b|\bAir Liquide\b/i
    regex_for_titleize_7 = /\bVictoria\b|\bQueensland\b|\bTasmania\b/i
    regex_for_titleize_8 = /\Air New Zealand\b|\bAir Pacific\b|\bAir Liquide\b|Singapore/i
    regex_for_titleize_9 = /\Be Our Guest\b|\bBlack Dog\b/i
    regex_for_titleize_10 = /\bJoe\b/i

    regex_for_downcase = /\bthe\b|\bof\b|\band\b|\bas\b|\bfor\b|\bis\b/i

    CapitalizeNames.capitalize(name.strip)
                   .gsub(regex_for_two_and_three_chars, &:upcase)
                   .gsub(regex_for_longer_acronyms_1, &:upcase)
                   .gsub(regex_for_longer_acronyms_2, &:upcase)
                   .gsub(regex_for_longer_acronyms_3, &:upcase)
                   .gsub(regex_for_longer_acronyms_4, &:upcase)
                   .gsub(regex_for_titleize, &:titleize)
                   .gsub(regex_for_titleize_2, &:titleize)
                   .gsub(regex_for_titleize_3, &:titleize)
                   .gsub(regex_for_titleize_4, &:titleize)
                   .gsub(regex_for_titleize_5, &:titleize)
                   .gsub(regex_for_titleize_6, &:titleize)
                   .gsub(regex_for_titleize_7, &:titleize)
                   .gsub(regex_for_titleize_8, &:titleize)
                   .gsub(regex_for_titleize_9, &:titleize)
                   .gsub(regex_for_titleize_10, &:titleize)
                   .gsub(regex_for_downcase, &:downcase)
                   .gsub(/^the/, &:titleize)
                   .gsub('australia', &:titleize)
                   .gsub(/Pty Limited|Pty\. Ltd\.|Pty Ltd\./, 'Pty Ltd')
                   .gsub(/PTE\.? Ltd\.?/i, 'Pte Ltd')
                   .gsub('(t/as Clubsnsw)', '(T/As ClubsNSW)')
  end
end