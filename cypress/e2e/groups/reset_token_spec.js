/// <reference types="cypress" />

context('Reset authentication token', () => {
  before(() => {
    cy.clearCookies()
  })


  beforeEach(() => {
    cy.visit('http://localhost:3000/users/sign_in')
    cy.loginAsAdmin()
  })

  afterEach(() => {
    cy.logout()
  })

  it('modifies the authentication token for groups in the same organization', () => {
    cy.visit('http://localhost:3000/')
    cy.contains('groups').click()
    cy.get('#groups_index').contains('td', 'Group 1').siblings(':nth-of-type(4)').first().invoke('text').then((oldAuthToken) => {
      cy.get('input.reset-tokens').contains('Reset tokens').click();
      cy.get('#groups_index').contains('td', 'Group 1').siblings(':nth-of-type(4)').first().invoke('text').then((newAuthToken) => {
        cy.get('#groups_index').contains('td', 'Group 1').siblings(':nth-of-type(4)').should('not.contain', oldAuthToken)
      })
    })
  })

  it('does not modify the authentication token for groups in other organization', () => {
    cy.visit('http://localhost:3000/')
    cy.contains('groups').click()
    cy.get('#groups_index').contains('td', 'Group 1').siblings(':nth-of-type(4)').first().invoke('text').then((oldAuthToken) => {
      cy.logout();
      cy.loginAsSecondAdmin();
      cy.contains('groups').click()
      cy.get('input.reset-tokens').contains('Reset tokens').click();
      cy.logout();
      cy.loginAsAdmin();
      cy.contains('groups').click()
      cy.get('#groups_index').contains('td', 'Group 1').siblings(':nth-of-type(4)').should('contain', oldAuthToken)
    })
  })
})
