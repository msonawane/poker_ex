import $ from 'jquery';
import Player from '../player';

export default class Controls {
  
  constructor(data) {
    this.player = data.user || null; // string
    this.channel = data.channel || null;
    this.to_call = data.to_call || 0;
    this.round = data.round[data.user] || 0;
    this.callDiv = $("#call-div");
    this.raiseDiv = $("#raise-div");
    this.checkDiv = $("#check-div");
    this.foldDiv = $("#fold-div");
    this.raiseBtn = $(".raise-control-btn");
    this.callBtn = $(".call-btn");
    this.checkBtn = $(".check-btn");
    this.foldBtn = $(".fold-btn");
  }
  
  update(state) {
    this.hideAllAndDetachEvents();
    this.to_call = state.to_call;
    this.round = state.round[this.player] || 0;
    console.log('Updating controls to this.to_call, this.round: ', this.to_call, this.round);
    let ctrls = this.selectCtrlTypes(state);
    (state.user) == state.active ? this.showAllAndAttachEvents(ctrls) : this.hideAllAndDetachEvents(); 
  }
  
  clear() {
    this.hideAllAndDetachEvents();
  }
  
  // Private
  
  show(type) {
    if (type == 'call') {
      console.log('editing call button');
      $("#call-amount-info").remove();
      this[`${type}Btn`].append($(`<span id="call-amount-info" class="white-text">${this.amountToCall()}</span>`));
    }
    this[`${type}Div`].fadeIn('slow');
    this[`${type}Btn`].fadeTo('slow', 1);
  }
  
  hide(type) {
    this[`${type}Div`].fadeOut('slow');
    this[`${type}Btn`].fadeTo('slow', 0);
  }
  
  showAll(ctrls) {
    ctrls.forEach((type) => {
      this.show(type);
    });
  }
  
  hideAll() {
    let ctrls = this.ctrlTypes();
    ctrls.forEach((type) => {
      this.hide(type);
    });
  }
  
  showAllAndAttachEvents(ctrls) {
    this.showAll(ctrls);
    this.attachClickEvents();
  }
  
  hideAllAndDetachEvents() {
    this.hideAll();
    this.detachClickEvents();
  }
  
  ctrlTypes() {
    return ["call", "raise", "check", "fold"];
  }
  
  selectCtrlTypes(state) {
    let paid = state.round[this.player] || 0;
    let chips = Player.filterPlayersArrayByName(state, this.player).chips;
    let ctrls;
    if (paid < state.to_call && chips > state.to_call) {
      ctrls = ["raise", "call", "fold"];
    } else if (paid < state.to_call && chips <= state.to_call) {
      ctrls = ["call", "fold"];
    } else if (paid >= state.to_call && chips > state.to_call) {
      ctrls = ["raise", "check"];
    } else {
      ctrls = ["check"];
    }
    return ctrls;
  }
  
  amountToCall() {
    console.log('Amount to call: ', this.to_call - this.round);
    return this.to_call - this.round;
  }
  
  attachClickEvents() {
    // Remove any lingering click handlers;
    let btns = [$(".call-btn"), $(".check-btn"), $(".fold-btn")];
    btns.forEach((btn) => {
      btn.off("click");
    });
    
    $(".call-btn").click((e) => {
      Player.call(this.player, this.channel);
      $("#controls-close").click();
      $(".call-btn").off("click");
    });
    $(".check-btn").click((e) => {
      Player.check(this.player, this.channel);
      $("#controls-close").click();
      $(".check-btn").off("click");
    });
    $(".fold-btn").click((e) => {
      Player.fold(this.player, this.channel);
      $("#controls-close").click();
      $(".fold-btn").off("click");
    });
  }
  
  detachClickEvents() {
    let btns = [".call-btn", ".check-btn", ".fold-btn"];
    btns.forEach((btn) => {
      removeEventListener('click', btn);
    });
  }
}