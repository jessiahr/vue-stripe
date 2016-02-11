

VueStripe = Vue.extend

  template: """
    <form class="vue-stripe">
      <div class="form-row">
        <label>
          <span v-if="showLabels">Card Number</span>
          <input maxlength="19" type="text" @keyup="formatCard($event)" v-model="number" size="20" v-bind:class="[validationErrors.number]" class="card-number" placeholder="{{placeholders.number}}"/>
        </label>
      </div>

      <div class="form-row">
        <label>
          <span v-if="showLabels">Expiration (MM/YYYY)</span>
          <div class="styled-select" v-bind:class="[validationErrors.expMonth]">
            <select v-model="expMonth" v-bind:class="[monthIsPlaceholder ? 'placeholder' : '']">
              <option disabled selected value="">{{placeholders.month}}</option>
              <option v-for="month in monthList">{{ month }}</option>
            </select>
          </div>
        </label>

        <label>
          <div class="styled-select" v-bind:class="[validationErrors.expYear]">
            <select v-model="expYear" v-bind:class="[yearIsPlaceholder ? 'placeholder' : '']">
              <option disabled selected value="">{{placeholders.year}}</option>
              <option v-for="year in yearList">{{ year }}</option>
            </select>
          </div>
        </label>

        <label>
          <span v-if="showLabels">CVC</span>
          <input type="text" v-bind:class="[validationErrors.cvc]" v-model="cvc" size="4" class="cvc" placeholder="{{placeholders.cvc}}"/>
        </label>
      </div>

      <span transition="expand" v-if="stripeError" class="error-text">{{stripeError.message}}</span>

      <div v-if="showButton" class="order-now">
        <button class="btn orange" @click.prevent="$root.kachingCreateCardToken()">charge me</button>
      </div>
    </form>
  """

  events:
    'VueStripe::create-card-token': ->
      @createToken()
    'VueStripe::reset-form': ->
      @resetKaching()

  data: ->
    stripeError: null
    number: ""
    cvc: ""
    expYear: ""
    expMonth: ""
    monthList: [1..12]
    placeholders:
      year: 'Year'
      month: 'Month'
      cvc: 'CVC'
      number: "Card Number"
    validationErrors:
      number: ""
      cvc: ""
      expYear: ""
      expMonth: ""

  ready: ->
    if @devMode
      @number = "4242424242424242"
      @cvc = "123"
      @expYear = "19"
      @expMonth = '1'

  props:
    showButton:
      default: true
    callback:
      required: false
    showLabels:
      default: false
    devMode:
      default: false
    shopUri:
      required: false
    card:
      required: true
      twoWay: true
    stripeKey:
      required: true

  computed:
    yearIsPlaceholder: ->
      @expYear.length == 0
    monthIsPlaceholder: ->
      @expMonth.length == 0
    yearList: ->
      today = new Date
      yyyy = today.getFullYear()
      years = for num in [yyyy.. (yyyy + 10)]
        num.toString().substr(2,2)
      return years

    cardParams: ->
      number: @number
      expMonth: @expMonth
      expYear: @expYear
      cvc: @cvc

  methods:
    resetKaching: ->
      console.log "resetting "
      @expMonth = ""
      @cvc = ""
      @expYear = ""
      @number = ""
      @card = null


    formatCard: (event) ->
      output = @number.split("-").join("")
      if (output.length > 0)
        output = output.replace(/[^\d]+/g,'')
        output = output.match(new RegExp('.{1,4}', 'g'))
        if output
          @number = output.join("-")
        else
          @number = ""

    createToken: ->
      Stripe.setPublishableKey(@stripeKey);
      Stripe.card.createToken @cardParams, @createTokenCallback

    createTokenCallback: (status, resp) ->
      @validationErrors =
        number: ""
        cvc: ""
        expYear: ""
        expMonth: ""
      @stripeError = resp.error
      if @stripeError
        @validationErrors.number = "error" if @stripeError.param == "number"
        @validationErrors.expYear = "error" if @stripeError.param == "exp_year"
        @validationErrors.expMonth = "error" if @stripeError.param == "exp_month"
        @validationErrors.cvc = "error" if @stripeError.param == "cvc"

      if (status == 200)
        @card = resp
        @callback() if @callback
        if @shopUri
          uploadReq = $.ajax
            method: 'post'
            url: @shopUri
            contentType: 'application/json; charset=utf-8'
            dataType: "json"
            data:
              JSON.stringify({card: @resp})



Vue.component 'vue-stripe', VueStripe
#
# Use a mixin to call createToken()
#
Vue.mixin({
  methods:
    vueStripeCreateCardToken: ->
      @$broadcast('VueStripe::create-card-token')
    kvueStripeResetForm: ->
      console.log 'reset me'
      @$broadcast('VueStripe::reset-form')
})
