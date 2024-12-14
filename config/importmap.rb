# Pin npm packages by running ./bin/importmap
# STILL USED BY PHLEX LAYOUTS FOR NOW!!

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin "jquery", to: "https://cdn.jsdelivr.net/npm/jquery/dist/jquery.js"

pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.1.3/dist/js/bootstrap.esm.js"
pin "@popperjs/core", to: "https://unpkg.com/@popperjs/core@2.11.2/dist/esm/index.js" # use unpkg.com as ga.jspm.io contains a broken popper package

pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"